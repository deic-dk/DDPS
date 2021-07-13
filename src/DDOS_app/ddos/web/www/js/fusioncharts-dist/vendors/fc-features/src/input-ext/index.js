import{componentFactory}from'../../../fc-core/src/lib';import InputManager from'./input-manager';import DragZoomIn from'./input-drag-zoom';import ZoomResetButton from'./zoom-reset';import ZoomOutButton from'./zoom-out';import ZoomInButton from'./zoom-in';import DbTapZoom from'./input-dbtap-zoom';import DragPin from'./input-drag-pin';import DragPan from'./input-pan';import PinchZoom from'./input-pinch-zoom';import SwipeGesture from'./input-swipe';import{getDep}from'../../../fc-core/src/dependency-manager';import raphaelShapesButton from'../../../fc-core/src/_internal/redraphael/redraphael-shapes/redraphael-shapes.button';let inputMap={DragZoomIn,ZoomResetButton,ZoomOutButton,DbTapZoom,DragPin,ZoomInButton,DragPan,PinchZoom,SwipeGesture};function inputAdapter(a){var b,c,d=getDep('redraphael','plugin');raphaelShapesButton(d),a.addEventListener('instantiated',function(a){let d,e=a.sender;'canvas'===e.getType()&&e.registerFactory('inputManager',function(a){if(c=a.getFromEnv('chart'),b=c.constructor.includeInputOptions&&c.constructor.includeInputOptions(),b){componentFactory(a,InputManager,'inputManager',1,[{}]),d=a.getChildren('inputManager')[0];for(let a=0,c=b&&b.length;a<c;a++)componentFactory(d,inputMap[b[a]],b[a],1,[{}])}})})}export default{extension:inputAdapter,name:'inputAdapter',type:'extension',requiresFusionCharts:!0};