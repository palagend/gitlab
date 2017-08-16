if Rails.env.development?
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/graphql'
end

post '/api/graphql', to: 'graphql#execute'
