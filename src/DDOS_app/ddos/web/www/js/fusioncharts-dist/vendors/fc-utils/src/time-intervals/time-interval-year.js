import TimeInterval from'./time-interval.js';class YearInterval extends TimeInterval{every(a){var b=Math.floor;const c=b(a);return this.count&&Number.isFinite(c)&&0<c?new TimeInterval('year',a=>{a.setFullYear(b(a.getFullYear()/c)*c),a.setMonth(0,1),a.setHours(0,0,0,0)},(a,b)=>a.setFullYear(a.getFullYear()+b*c)):null}}export default YearInterval;