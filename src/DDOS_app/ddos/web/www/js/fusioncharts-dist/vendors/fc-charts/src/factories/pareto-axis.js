import NumericAxis from'../../../fc-core/src/axis/numeric';import CategoryAxis from'../../../fc-core/src/axis/category';import{componentFactory,pluckNumber}from'../../../fc-core/src/lib';export default function(a){let b,c,d,e=a.getFromEnv('chart-attrib'),f=pluckNumber(e.showcumulativeline,1),g=a.getChildren('canvas')[0],h=g.getChildren('axisRefVisualCartesian')[0],i={zoomable:!0,pannable:!0},j=a._feedAxesRawData(),k=()=>h.asyncDraw();componentFactory(a,CategoryAxis,'xAxis',1,j.xAxisConf),b=a.getChildren(),d=b.xAxis[0],h.setLinkedItem(d.getId(),d),g.attachAxis(d,!1,a.zoomX?i:{}),d.setLinkedItem('canvas',g),componentFactory(a,NumericAxis,'yAxis',f?2:1,j.yAxisConf),c=a.getChildren('yAxis'),c&&c[1]&&c[1].setAxisConfig({isPercent:!0,drawLabels:!0,drawPlotLines:!0,drawAxisName:!0,drawAxisLine:!0,drawPlotBands:!0,drawTrendLines:!0,drawTrendLabels:!0}),c.forEach(b=>{!0===b.getState('removed')?g.detachAxis(b):(b.setLinkedItem('canvas',g),h.setLinkedItem(b.getId(),b),g.attachAxis(b,!0,a.zoomY?i:{}),h.setLinkedItem(b.getId(),b),h.addExtEventListener('visiblerangeset',k,b))}),a._setCategories()}