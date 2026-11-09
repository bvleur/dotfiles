"use strict";var m=Object.defineProperty;var k=Object.getOwnPropertyDescriptor;var x=Object.getOwnPropertyNames;var L=Object.prototype.hasOwnProperty;var D=(o,e)=>{for(var n in e)m(o,n,{get:e[n],enumerable:!0})},M=(o,e,n,r)=>{if(e&&typeof e=="object"||typeof e=="function")for(let i of x(e))!L.call(o,i)&&i!==n&&m(o,i,{get:()=>e[i],enumerable:!(r=k(e,i))||r.enumerable});return o};var E=o=>M(m({},"__esModule",{value:!0}),o);var N={};D(N,{default:()=>W});module.exports=E(N);var t=require("@vicinae/api"),u=require("react");var y=require("@vicinae/api"),b=require("node:child_process"),F=require("node:util"),p=(0,F.promisify)(b.execFile);async function c(o){let{stdout:e}=await p("osascript",["-e",o]);return e.trim()}var I=`
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
`;async function g(){return(await c(I)).split(`
`).filter(Boolean).map(e=>{let[n,r,i]=e.split("	");return{id:Number(n),name:r,path:i??""}})}var _="com.apple.finder";async function v(){try{let{stdout:o}=await p("lsappinfo",["front"]),{stdout:e}=await p("lsappinfo",["info","-only","bundleid",o.trim()]);return e.match(/"([^"]+)"\s*$/)?.[1]??e.trim()}catch{return""}}var C=v(),V=Number(process.env.FF_GUARD_MAX_MS??800);async function d(o){let{keepFocus:e}=(0,y.getPreferenceValues)(),n=e===!1?"":await C;if(n.toLowerCase().includes("vicinae")&&(n=""),await o(),e===!1)return;let r=Date.now(),i=null;for(;Date.now()-r<V;){await new Promise(f=>setTimeout(f,60));let l=await v();if(l===_){if(i??=Date.now(),Date.now()-i>=300)return}else if(n===""||l===n||l==="")i=null,await c('tell application "Finder" to activate');else return}}async function h(){await c(`
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
  `)}async function P(o){await c(`
    tell application "Finder"
      set w to window id ${Math.trunc(o)}
      if collapsed of w then set collapsed of w to false
      set index of w to 1
      activate
    end tell
  `)}async function A(){await c(`
    tell application "Finder" to activate
    tell application "System Events"
      tell process "Finder"
        set wm to (first menu bar item of menu bar 1 whose name is "Window" or name is "Venster")
        set mi to missing value
        repeat with m in (menu items of menu 1 of wm)
          set n to ""
          try
            set n to name of m
          end try
          if n is "Merge All Windows" or n is "Alle vensters samenvoegen" or n is "Voeg alle vensters samen" then
            set mi to m
            exit repeat
          end if
        end repeat
        if mi is missing value then error "merge menu item not found"
        click mi
      end tell
    end tell
  `)}function w(o){let e=o instanceof Error?o.message:String(o);return e.includes("-1743")?"Allow Vicinae to control Finder in Privacy & Security > Automation":e.includes("-1719")||e.includes("-25211")?"Allow Vicinae in Privacy & Security > Accessibility":"Could not talk to Finder"}var a=require("react/jsx-runtime");function W(o){let{alwaysShowList:e}=(0,t.getPreferenceValues)(),n=o.launchContext?.windows,[r,i]=(0,u.useState)(()=>{try{return typeof n=="string"?JSON.parse(n):null}catch{return null}}),l=async()=>{await(0,t.closeMainWindow)();try{await A()}catch(s){await(0,t.showHUD)(w(s))}};(0,u.useEffect)(()=>{r===null&&(async()=>{try{let s=await g();if(!e&&s.length<=1){await(0,t.closeMainWindow)(),await d(h);return}i(s)}catch(s){await(0,t.closeMainWindow)(),await(0,t.showHUD)(w(s))}})()},[]);let f=async s=>{await(0,t.closeMainWindow)();try{await d(()=>P(s.id))}catch(S){await(0,t.showHUD)(w(S))}};return(0,a.jsxs)(t.List,{isLoading:r===null,searchBarPlaceholder:"Filter Finder windows\u2026",children:[(r??[]).map(s=>(0,a.jsx)(t.List.Item,{title:s.name,subtitle:s.path.replace(/^\/Users\/[^/]+/,"~"),icon:t.Icon.Folder,actions:(0,a.jsxs)(t.ActionPanel,{children:[(0,a.jsx)(t.Action,{title:"Focus Window",onAction:()=>f(s)}),(0,a.jsx)(t.Action,{title:"Focus Finder",onAction:async()=>{await(0,t.closeMainWindow)(),await d(h)}})]})},s.id)),r&&r.length>1&&(0,a.jsx)(t.List.Item,{title:"Merge all windows into one",icon:t.Icon.Layers,actions:(0,a.jsx)(t.ActionPanel,{children:(0,a.jsx)(t.Action,{title:"Merge All Windows",onAction:l})})},"merge")]})}
