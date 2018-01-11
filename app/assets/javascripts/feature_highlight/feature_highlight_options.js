import { highlightFeatures } from './feature_highlight';
import bp from '../breakpoints';

const highlightOrder = ['clusters'];

export default function domContentLoaded(order) {
  if (bp.getBreakpointSize() === 'lg') {
    highlightFeatures(order);
  }
}

document.addEventListener('DOMContentLoaded', domContentLoaded.bind(this, highlightOrder));
