import polarCanvas from'../_internal/components/canvases/polar-canvas';import axisRefVisualPolar from'../../../fc-core/src/axis-ref-visuals/axis-ref-polar-component';import{componentFactory}from'../../../fc-core/src/lib';export default function(a){let b;componentFactory(a,polarCanvas,'canvas',a.config.showVolumeChart?2:1),b=a.getChildren('canvas');for(let c=0,d=b.length;c<d;c++)b[c].configure(),componentFactory(b[c],axisRefVisualPolar,'axisRefVisualPolar')}