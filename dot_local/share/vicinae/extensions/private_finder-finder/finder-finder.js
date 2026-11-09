"use strict";var l=Object.defineProperty;var F=Object.getOwnPropertyDescriptor;var P=Object.getOwnPropertyNames;var x=Object.prototype.hasOwnProperty;var A=(t,e)=>{for(var o in e)l(t,o,{get:e[o],enumerable:!0})},S=(t,e,o,s)=>{if(e&&typeof e=="object"||typeof e=="function")for(let n of P(e))!x.call(t,n)&&n!==o&&l(t,n,{get:()=>e[n],enumerable:!(s=F(e,n))||s.enumerable});return t};var W=t=>S(l({},"__esModule",{value:!0}),t);var C={};A(C,{default:()=>g});module.exports=W(C);var i=require("@vicinae/api");var c=require("@vicinae/api"),w=require("node:child_process"),u=require("node:util"),d=(0,u.promisify)(w.execFile);async function r(t){let{stdout:e}=await d("osascript",["-e",t]);return e.trim()}var k=`
tell application "Finder"
  set out to ""
  repeat with i from 1 to (count of windows)
    set w to window i
    set p to ""
    try
      set p to POSIX path of (target of w as alias)
    end try
    set out to out & ((id of w) as string) & "	" & (name of w) & "	" & p & linefeed
  end repeat
  return out
end tell
`;async function f(){return(await r(k)).split(`
`).filter(Boolean).map(e=>{let[o,s,n]=e.split("	");return{id:Number(o),name:s,path:n??""}})}var D="com.apple.finder";async function m(){try{let{stdout:t}=await d("lsappinfo",["front"]),{stdout:e}=await d("lsappinfo",["info","-only","bundleid",t.trim()]);return e.match(/"([^"]+)"\s*$/)?.[1]??e.trim()}catch{return""}}var M=m(),_=Number(process.env.FF_GUARD_MAX_MS??800);async function p(t){let{keepFocus:e}=(0,c.getPreferenceValues)(),o=e===!1?"":await M;if(o.toLowerCase().includes("vicinae")&&(o=""),await t(),e===!1)return;let s=Date.now(),n=null;for(;Date.now()-s<_;){await new Promise(v=>setTimeout(v,60));let a=await m();if(a===D){if(n??=Date.now(),Date.now()-n>=300)return}else if(o===""||a===o||a==="")n=null,await r('tell application "Finder" to activate');else return}}async function h(){await r(`
    tell application "Finder"
      if (count of windows) is 0 then
        set b to bounds of window of desktop
        set sw to (item 3 of b) - (item 1 of b)
        set sh to (item 4 of b) - (item 2 of b)
        set w to round (sw * 0.6)
        set h to round (sh * 0.7)
        set l to (item 1 of b) + round ((sw - w) / 2)
        set t to (item 2 of b) + round ((sh - h) / 2)
        set nw to make new Finder window
        set bounds of nw to {l, t, l + w, t + h}
      end if
      activate
    end tell
  `)}async function b(t){await r(`
    tell application "Finder"
      set w to window id ${Math.trunc(t)}
      if collapsed of w then set collapsed of w to false
      set index of w to 1
      activate
    end tell
  `)}function y(t){let e=t instanceof Error?t.message:String(t);return e.includes("-1743")?"Allow Vicinae to control Finder in Privacy & Security > Automation":e.includes("-1719")||e.includes("-25211")?"Allow Vicinae in Privacy & Security > Accessibility":"Could not talk to Finder"}async function g(){try{let t=await f();if(t.length>1){await(0,i.launchCommand)({name:"finder-windows",type:i.LaunchType.UserInitiated,context:{windows:JSON.stringify(t)}});return}await(0,i.closeMainWindow)(),await p(()=>t.length===1?b(t[0].id):h())}catch(t){await(0,i.closeMainWindow)(),await(0,i.showHUD)(y(t))}}
