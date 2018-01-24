import Flash from '../flash';
import { s__ } from '../locale';
import ToggleButtons from '../toggle_buttons';
import ClustersService from './services/clusters_service';

export default () => {
  const toggleButtons = new ToggleButtons(
    document.querySelector('.js-clusters-list'),
    (value, toggle) =>
      ClustersService.updateCluster(toggle.dataset.endpoint, { cluster: { enabled: value } })
        .catch((err) => {
          Flash(s__('ClusterIntegration|Something went wrong on our end.'));
          throw err;
        }),
  );
  toggleButtons.init();
};
