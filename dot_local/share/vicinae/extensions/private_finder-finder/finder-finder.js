"use strict";var a=Object.defineProperty;var b=Object.getOwnPropertyDescriptor;var y=Object.getOwnPropertyNames;var g=Object.prototype.hasOwnProperty;var v=(t,e)=>{for(var i in e)a(t,i,{get:e[i],enumerable:!0})},F=(t,e,i,s)=>{if(e&&typeof e=="object"||typeof e=="function")for(let n of y(e))!g.call(t,n)&&n!==i&&a(t,n,{get:()=>e[n],enumerable:!(s=b(e,n))||s.enumerable});return t};var P=t=>F(a({},"__esModule",{value:!0}),t);var k={};v(k,{default:()=>h});module.exports=P(k);var o=require("@vicinae/api");var l=require("node:child_process"),w=require("node:util"),d=(0,w.promisify)(l.execFile);async function r(t){let{stdout:e}=await d("osascript",["-e",t]);return e.trim()}var x=`
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
`;async function c(){return(await r(x)).split(`
`).filter(Boolean).map(e=>{let[i,s,n]=e.split("	");return{id:Number(i),name:s,path:n??""}})}var W="com.apple.finder";async function S(){try{let{stdout:t}=await d("lsappinfo",["front"]),{stdout:e}=await d("lsappinfo",["info","-only","bundleid",t.trim()]);return e.includes(W)}catch{return!0}}async function m(t){await t();for(let e=0;e<10;e++)await new Promise(i=>setTimeout(i,120)),await S()||await r('tell application "Finder" to activate')}async function f(){await r(`
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
  `)}async function u(t){await r(`
    tell application "Finder"
      set w to window id ${Math.trunc(t)}
      if collapsed of w then set collapsed of w to false
      set index of w to 1
      activate
    end tell
  `)}function p(t){let e=t instanceof Error?t.message:String(t);return e.includes("-1743")?"Allow Vicinae to control Finder in Privacy & Security > Automation":e.includes("-1719")||e.includes("-25211")?"Allow Vicinae in Privacy & Security > Accessibility":"Could not talk to Finder"}async function h(){try{let t=await c();if(t.length>1){await(0,o.launchCommand)({name:"finder-windows",type:o.LaunchType.UserInitiated,context:{windows:JSON.stringify(t)}});return}await(0,o.closeMainWindow)(),await m(()=>t.length===1?u(t[0].id):f())}catch(t){await(0,o.closeMainWindow)(),await(0,o.showHUD)(p(t))}}
