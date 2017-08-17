class Loaders::IidLoader < Loaders::BaseLoader
  attr_reader :model, :parent_key, :action

  # Returns a proc that allows args['iid'] to be an array of values. An empty
  # array requests all the instances of the model on the parent.
  def self.array_resolver(model, parent_key, action:)
    resolver = new(model, parent_key, action: action)

    return ->(parent, args, ctx) {
      iids = Array(args['iid']).compact.uniq

      if iids.present?
        Promise.all(iids.map { |iid| resolver.call_by_iid(parent, iid, ctx) })
      else
        resolver.call_by_iid(parent, :any, ctx)
      end
    }
  end

  # Load an instance of a model by `iid`. Provide an action like `read_issue` or
  # `update_merge_request` if you wish to use this loader as a resolver and need
  # to apply access controls.
  def initialize(model, parent_key, action:)
    super(action: action)

    @model = model
    @parent_key = parent_key
  end

  # Allow the loader to be used as a resolver as well. Access control is
  # performed here.
  #
  # TODO(nick.thomas): is it always safe to check the access against the parent,
  # rather than the child? If so, we can short-circuit a lot of work here, e.g.:
  #
  # if can?(ctx, action, parent)
  #   ...
  # else
  #   nil # or at least a promise that resolves to nil without any DB work
  # end
  #
  # Since `iid` is always scoped by parent object, `parent` must be present.
  def call(parent, args, ctx)
    call_by_iid(parent, args['iid'], ctx)
  end

  def call_by_iid(parent, iid, ctx)
    # GraphQL IDs are always strings
    tuple = [parent.id.to_s, iid]

    filter_by_action(load(tuple), ctx)
  end

  # `keys` is an array of [parent_id, iid] tuples. If `iid == :any`, we load
  # all the children of the parent
  def perform(keys)
    any, some = keys.partition { |(k, v)| v == :any }

    perform_any(any) if any.present?
    perform_some(some) if some.present?
  end

  private

  # Find all the children of a set of parents.
  def perform_any(keys)
    found = build_relation(keys, any: true).all
    tuples = found.map { |instance| [[parent_id(instance), :any], instance] }
    hashed = hashify_tuples(tuples)

    fulfill_all(keys, hashed)
  end

  # Find some children of a set of parents, filtered by IID.
  def perform_some(keys)
    found = build_relation(keys).all
    fulfill_all(keys, found.index_by {|instance| iid_tuple(instance) })
  end

  def build_relation(keys, any: false)
    relations = hashify_tuples(keys).map do |parent_id, iids|
      relation = model.where(parent_key => parent_id)
      relation = relation.where(iid: iids) unless any
      relation.select(:id)
    end

    return model.none if relations.empty?

    sql = Gitlab::SQL::Union.new(relations).to_sql
    model.where('id IN (' + sql + ')')
  end

  # Converts an array like `[[k, v1], [k, v2]]` into a hash like `{ k => [v1, v2] }`
  def hashify_tuples(tuples)
    hash = Hash.new {|h, k| h[k] = [] }

    tuples.each_with_object(hash) { |(k, v), obj| obj[k] << v }
  end

  def iid_tuples(instances)
    instances.map { |instance| iid_tuple(instance) }
  end

  def parent_id(instance)
    instance.public_send(parent_key).to_s
  end

  def iid_tuple(instance, override_iid = nil)
    iid = override_iid || instance.iid.to_s

    [parent_id(instance), iid]
  end
end
