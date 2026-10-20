"use strict";var n=Object.defineProperty;var l=Object.getOwnPropertyDescriptor;var d=Object.getOwnPropertyNames;var p=Object.prototype.hasOwnProperty;var u=(e,t)=>{for(var r in t)n(e,r,{get:t[r],enumerable:!0})},f=(e,t,r,i)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of d(t))!p.call(e,o)&&o!==r&&n(e,o,{get:()=>t[o],enumerable:!(i=l(t,o))||i.enumerable});return e};var y=e=>f(n({},"__esModule",{value:!0}),e);var S={};u(S,{default:()=>m});module.exports=y(S);var a=require("@vicinae/api"),s=require("node:child_process"),c=require("node:util"),w=(0,c.promisify)(s.execFile),g=`
tell application "System Events"
  tell appearance preferences
    set dark mode to not dark mode
    return dark mode
  end tell
end tell
`;async function m(){await(0,a.closeMainWindow)();try{let{stdout:e}=await w("osascript",["-e",g]);await(0,a.showHUD)(e.trim()==="true"?"Dark mode":"Light mode")}catch(e){let t=e instanceof Error?e.message:String(e);await(0,a.showHUD)(t.includes("-1743")?"Allow Vicinae to control System Events in Privacy & Security > Automation":"Failed to toggle system appearance")}}
