const validDataset=['scatter','bubble','errorScatter','selectScatter'];let isDataset=a=>'dataset'===a.getType(),isValidDataset=a=>isDataset(a)&&0<=validDataset.indexOf(a.getName());function createLinear(a,b){let c=+a.showregressionline||0,d=isNaN(b.showregressionline)&&c||+b.showregressionline;return d}function createPolynomial(a,b){let c=+a.showpolynomialregressionline||0,d=isNaN(b.showpolynomialregressionline)&&c||+b.showpolynomialregressionline;return d}function isInArray(a,b){return a=a.toLowerCase(),-1<b.indexOf(a)}function hasRegressionLine(a,b){return b.showregressionline||a.showregressionline||b.showpolynomialregressionline||a.showpolynomialregressionline}export{createPolynomial,createLinear,isInArray,hasRegressionLine,isValidDataset};