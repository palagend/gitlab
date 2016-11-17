((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.CycleAnalyticsStore = {
    state: {
      summary: '',
      stats: '',
      analytics: '',
      events: [],
      stages:[],
    },
    setCycleAnalyticsData(data) {
      this.state = Object.assign(this.state, this.decorateData(data));
    },
    decorateData(data) {
      let newData = {};

      newData.stages = data.stats || [];
      newData.summary = data.summary || [];

      newData.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      newData.stages.forEach((item) => {
        item.value = item.value || '- - -';
        item.active = false;
        item.component = `stage-${item.title.toLowerCase()}-component`;
      });

      newData.analytics = data;

      return newData;
    },
    setLoadingState(state) {
      this.state.isLoading = state;
    },
    setErrorState(state) {
      this.state.hasError = state;
    },
    deactivateAllStages() {
      this.state.stages.forEach(stage => {
        stage.active = false;
      });
    },
    setActiveStage(stage) {
      this.deactivateAllStages();
      stage.active = true;
    },
    setStageEvents(events) {
      this.state.events = this.decorateEvents(events);
    },
    decorateEvents(events) {
      let newEvents = events;

      newEvents.forEach((item) => {
        item.totalTime = item.total_time;
        item.createdAt = item.created_at;
        item.author.webUrl = item.author.web_url;
        item.author.avatarUrl = item.author.avatar_url;

        if (item.short_sha) {
          item.shortSha = item.short_sha;
        }

        delete item.author.web_url;
        delete item.author.avatar_url;
        delete item.total_time;
        delete item.created_at;
        delete item.short_sha;
      });

      return newEvents;
    },
    currentActiveStage() {
      return this.state.stages.find(stage => stage.active);
    },
  };

})(window.gl || (window.gl = {}));
