import Legend from'../../../../fc-charts/src/_internal/components/legend/discrete';import{componentFactory,pluck,convertColor,pluckNumber}from'../../../../fc-core/src/lib';const COLOR_5F5F5F='#5f5f5f';export default(a=>{let b,c=a.config.showLegend,d=a.config.mergedLegendStyle,e=d.color=pluck(d.fill,COLOR_5F5F5F),f=pluckNumber(d.opacity,1),g=pluckNumber(d['fill-opacity'],1),h=Object.assign({},a.getFromEnv('baseTextStyle'),d);if(h['font-size']=+(h['font-size']+'').replace(/px/,''),c){componentFactory(a,Legend,'legend',1,[{drawcustomlegendicon:1,legendiconsides:4,alignlegendwithcanvas:1,legendborderthickness:0,legendiconscale:1.3,legendbgalpha:0,legendFontColor:e,style:{text:h}}]),b=a.getChildren('legend')[0],a.addToEnv('legend',b),b.setStateCosmetics('hover',function(a,b){return b.hasState('hidden')||(!a.text&&(a.text={}),a.text.fill=convertColor(e,100*(f*g)),a.text.cursor='inherit'),a});const c=(b={})=>{for(const d in b)if(b.hasOwnProperty(d)){const e=b[d];e.hasOwnProperty('visibility')?a._addLegend(e):c(e)}};c(a.getFromEnv('legendMap'))}else(b=a.getChildren('legend')&&a.getChildren('legend')[0])&&b.remove()});