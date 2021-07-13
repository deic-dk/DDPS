import{stubFN,preDefStr,pluckNumber,extend2}from'../../../../fc-core/src/lib';import FunnelPyramidBaseDataset from'../_internal/funnelpyramidbase';import{priorityList}from'../../../../fc-core/src/schedular';import PyramidPoint from'../_internal/data/pyramid-point';var UNDEF,POSITION_START=preDefStr.POSITION_START,POSITION_MIDDLE=preDefStr.POSITION_MIDDLE;class PyramidDataset extends FunnelPyramidBaseDataset{constructor(){super(),this.preDrawingHook=function(){},this.config.pointInContext=PyramidPoint,this.config.LABEL_PLACEMENT_ITERATOR_INDEX_START=0}getType(){return'dataset'}getName(){return'pyramid'}configure(a){if(!a)return!1;this.config.JSONData=a;var b=this,c=b.getFromEnv('chartConfig');b._checkValidData(b.config.JSONData.data)&&(b._configure(),c.showLegend&&b.addLegend())}configureSpecifics(){var a=this,b=a.getFromEnv('chart'),c=a.config,d=b.getFromEnv('dataSource')?b.getFromEnv('dataSource').chart:{},e=a.utils(a),f=e.copyProperties;f(d,c,[['pyramidyscale','yScale',pluckNumber,UNDEF,function(a){var b=a.yScale;a.yScale=0<=b&&40>=b?b/200:.2}],['use3dlighting','use3DLighting',pluckNumber,1]])}calculatePositionOfPlots(){var a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r=Math.floor,s=this,t=s.getFromEnv('chart'),u=t.config,v=s.config,w=s.utils(s),x=w.DistributionMatrix,y=s.calculatePositionCoordinate,z=v.psmMargin,A=s.getChildren('data'),B=2,C=A.length,D=0,E=0,F=v.lineHeight,G=r;for(s.postPlotCallback=stubFN,u.canvasTop+=u.marginTop-z.top,u.effCanvasHeight=e=u.canvasHeight-(u.marginTop+u.marginBottom)+(z.top+z.bottom),u.effCanvasWidth=f=u.width-(u.marginLeft+u.marginRight),g=v.drawingRadius=f/B,v.x=g+u.canvasLeft,q=Math.atan(f/2/e),v.unitHeight=d=e/v.sumValue,v.lastRadius=0,v.globalMinXShift=r(F/Math.cos(q)),h=v.alignmentType={},h['default']=1,h.alternate=2,p=new x(G(e/F)),(a=0,b=C);a<b;a++)(c=A[a],!c.getState('removed'))&&(D=c.y*d,E+=c.y*d,j=E-D+D/2,i=G(j/F),p.push(c,i));if(k=p.getDistributedResult(),A.length=0,k.matrix[1]===UNDEF)[].push.apply(A,k.matrix[0]);else for(l=k.matrix[0],m=k.matrix[1],b=Math.max(l.length,m.length),a=0;a<b;a++)o=l[a],n=m[a],A.push(o||n);switch(k.suggestion){case h['default']:y.call(s,A,!1);break;case h.alternate:v.labelAlignment=h.alternate,B=3,v.drawingRadius=g=f/B,u.canvasLeft=u.canvasWidth/2-g,v.x=u.canvasLeft+g,y.call(s,A,!0);}}draw(){var a,b,c,d,e,f,g,h=this,i=h.getFromEnv('chart'),j=h.config,k=h.config.trackerArgs=[],l=h.getChildren('data'),m=l.length,n=Math.min;if(j.sumValue){for(h.config.labelDrawingConfig=h.config.labelDrawingConfig||[],h.config.labelDrawingConfig.length=0,h.animateFunction=function(a){return function(){a.attr({opacity:1})}},c=j.slicingDistance,e=c/2,(a=0,b=l.length);a<b;a++)l[a]&&l[a].shapeArgs&&(l[a].shapeArgs.renderer=i.getFromEnv('paper'));for(d=j.noOfGap,d&&(j.perGapDistance=n(1.5*e,c/d),j.distanceAvailed=e),a=l.length,j.alreadyPlotted&&(h.postPlotCallback=function(){g||(g=!0)});a--;)f=l[a],f.index=a,f.syncDraw();for(j.oldLastData=Object.assign({},l[l.length-1].shapeArgs),h.hide(h.getChildren('data'),m),j.connectorEndSwitchHistoryY={},a=l.length;a--;)k.push(l[a]);h.addJob('labelDrawID',h.drawAllLabels.bind(h),priorityList.label),h.addJob('trackerDrawID',h.drawAllTrackers.bind(h),priorityList.tracker),h.removePlots(),j.alreadyPlotted=!0,j.prevIs2d=j.is2d}}calculatePositionCoordinate(a,b){var c,d,e,f,g,h,i,j,k,l=this,m=l.config,n=m.is2d,o=m.x,p=l.getFromEnv('chart'),q=p.config,r=q.canvasTop,s=m.unitHeight,t=m.labelDistance,u=m.showLabelsAtCenter,v=q.style.fontSize,w=.3*v,x=m.yScale,z=m.blankSpace,A=m.lastRadius,B=l.getFromEnv('smartLabel'),C=a.length-1,D=!1,E=0,F=m.lineHeight,G=0,H={flag:!1,point:UNDEF,sLabel:UNDEF,setAll:function(a,b,c){this.flag=a,this.point=b,this.sLabel=c}},I={point:UNDEF,sLabel:UNDEF,set:function(a,b){var c=a;return function(a,d){var e,f;return a.dontPlot?void 0:this.point&&this.sLabel?void(e=c(this.point,this.sLabel),f=c(a,d),b(e,f)&&(this.point=a,this.sLabel=d)):(this.point=a,void(this.sLabel=d))}}},J={},K={},L={},M={},N=p.config.width-2,O=m.slicingGapPosition={};for(extend2(J,H),extend2(K,H),J.setAll=function(a,b,c){var d,e,f=this.point,g=this.sLabel;return this.flag=a,f&&g?void(d=f.labelX-(g.oriTextWidth-g.width),e=b.labelX-(c.oriTextWidth-c.width),d>e&&(this.point=b,this.sLabel=c)):(this.point=b,void(this.sLabel=c))},K.setAll=function(a,b,c){var d,e,f=this.point,g=this.sLabel;return this.flag=a,f&&g?void(d=f.labelX+g.oriTextWidth,e=b.labelX+c.oriTextWidth,d<e&&(this.point=b,this.sLabel=c)):(this.point=b,void(this.sLabel=c))},extend2(L,I),extend2(M,I),L.set=function(){return I.set.apply(L,[function(a){return a.labelX},function(a,b){return a>b}])}(),M.set=function(){return I.set.apply(M,[function(a,b){return a.labelX+b.oriTextWidth},function(a,b){return a<b}])}(),m.noOfGap=0,B.useEllipsesOnOverflow(q.useEllipsesWhenOverflow),(c=0,d=a.length);c<d;c++)(e=a[c],!!e)&&(e.x=c,e.plot&&(e.isSliced=!!e.isSliced||!!m.isSliced),e.isSliced=pluckNumber(e.isSliced,m.isSliced),b&&(D=!D),e.isSliced&&(k=e.x,k&&!O[k]&&(O[k]=!0,m.noOfGap+=1),k<C&&(O[k+1]=!0,m.noOfGap+=1)),B.setStyle(e.style),e.oriText=e.displayValue,g=g=B.getSmartText(e.displayValue,Number.POSITIVE_INFINITY,Number.POSITIVE_INFINITY),G+=e.y,h=m.drawingRadius*G/m.sumValue,f=s*e.y,e.shapeArgs={x:o,y:r,R1:A,R2:h,h:f,r3dFactor:x,gStr:'point',is2D:n,use3DLighting:!!m.use3DLighting,renderer:l.getFromEnv('paper')},u?(e.labelAline=POSITION_MIDDLE,e.labelX=o,e.labelY=(n?r:r+x*A)+f/2+w):(e.labelAline=POSITION_START,e.alignmentSwitch=D,e.distributionFactor=e.distributionFactor||0,D?(e.labelX=o-(t+(h+A)/2+z+g.width),e.labelX-=e.distributionFactor*m.globalMinXShift,L.set(e,g)):(e.labelX=o+t+(h+A)/2+z,e.labelX+=e.distributionFactor*m.globalMinXShift,M.set(e,g)),E=e.distributionFactor*F,e.labelY=r+w+f/2+E),b&&(D&&0>e.labelX?(i=e.labelX+g.width,j=B.getSmartText(e.displayValue,i,Number.POSITIVE_INFINITY,!0),e.labelX=2,e.isLabelTruncated=!0,e.displayValue=j.text,e.virtualWidth=j.maxWidth,J.setAll(!0,e,j)):!D&&e.labelX+g.width>N&&(j=B.getSmartText(e.displayValue,N-e.labelX,Number.POSITIVE_INFINITY,!0),e.isLabelTruncated=!0,e.displayValue=j.text,e.virtualWidth=j.maxWidth,K.setAll(!0,e,j)),e.pWidth=e.virtualWidth||g.width,E=e.distributionFactor*F,e.labelY=r+w+f/2+E),r+=f,e.plotX=o,e.plotY=r-f/2,A=h,e.virtualWidth=e.virtualWidth||g.width);l.findBestPosition(a,{lTrimmedInfo:J,rTrimmedInfo:K,lLargestLabel:L,rLargestLabel:M})}getTooltipMacroStub(a){var b,c,d=this,e=d.config,f=d.getFromEnv('number-formatter');return c=e.percentOfPrevious?a.pValue:f.percentValue(100*(a.dataValue/a.prevValue)),b=super.getTooltipMacroStub(a),b.percentValue=e.percentOfPrevious?f.percentValue(100*(a.dataValue/a.highestValue)):a.pValue,b.percentOfPrevValue=c,b}}export default PyramidDataset;