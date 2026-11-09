"use strict";var u=Object.defineProperty;var A=Object.getOwnPropertyDescriptor;var x=Object.getOwnPropertyNames;var S=Object.prototype.hasOwnProperty;var k=(o,e)=>{for(var i in e)u(o,i,{get:e[i],enumerable:!0})},L=(o,e,i,s)=>{if(e&&typeof e=="object"||typeof e=="function")for(let a of x(e))!S.call(o,a)&&a!==i&&u(o,a,{get:()=>e[a],enumerable:!(s=A(e,a))||s.enumerable});return o};var I=o=>L(u({},"__esModule",{value:!0}),o);var V={};k(V,{default:()=>g});module.exports=I(V);var t=require("@vicinae/api"),w=require("react");var p=require("node:child_process"),h=require("node:util"),m=(0,h.promisify)(p.execFile);async function l(o){let{stdout:e}=await m("osascript",["-e",o]);return e.trim()}var E=`
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
`;async function y(){return(await l(E)).split(`
`).filter(Boolean).map(e=>{let[i,s,a]=e.split("	");return{id:Number(i),name:s,path:a??""}})}var C="com.apple.finder";async function M(){try{let{stdout:o}=await m("lsappinfo",["front"]),{stdout:e}=await m("lsappinfo",["info","-only","bundleid",o.trim()]);return e.includes(C)}catch{return!0}}async function d(o){await o();for(let e=0;e<10;e++)await new Promise(i=>setTimeout(i,120)),await M()||await l('tell application "Finder" to activate')}async function f(){await l(`
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
  `)}async function b(o){await l(`
    tell application "Finder"
      set w to window id ${Math.trunc(o)}
      if collapsed of w then set collapsed of w to false
      set index of w to 1
      activate
    end tell
  `)}async function F(){await l(`
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
  `)}function c(o){let e=o instanceof Error?o.message:String(o);return e.includes("-1743")?"Allow Vicinae to control Finder in Privacy & Security > Automation":e.includes("-1719")||e.includes("-25211")?"Allow Vicinae in Privacy & Security > Accessibility":"Could not talk to Finder"}var r=require("react/jsx-runtime");function g(o){let{alwaysShowList:e}=(0,t.getPreferenceValues)(),i=o.launchContext?.windows,[s,a]=(0,w.useState)(()=>{try{return typeof i=="string"?JSON.parse(i):null}catch{return null}}),P=async()=>{await(0,t.closeMainWindow)();try{await F()}catch(n){await(0,t.showHUD)(c(n))}};(0,w.useEffect)(()=>{s===null&&(async()=>{try{let n=await y();if(!e&&n.length<=1){await(0,t.closeMainWindow)(),await d(f);return}a(n)}catch(n){await(0,t.closeMainWindow)(),await(0,t.showHUD)(c(n))}})()},[]);let v=async n=>{await(0,t.closeMainWindow)();try{await d(()=>b(n.id))}catch(W){await(0,t.showHUD)(c(W))}};return(0,r.jsxs)(t.List,{isLoading:s===null,searchBarPlaceholder:"Filter Finder windows\u2026",children:[(s??[]).map(n=>(0,r.jsx)(t.List.Item,{title:n.name,subtitle:n.path.replace(/^\/Users\/[^/]+/,"~"),icon:t.Icon.Folder,actions:(0,r.jsxs)(t.ActionPanel,{children:[(0,r.jsx)(t.Action,{title:"Focus Window",onAction:()=>v(n)}),(0,r.jsx)(t.Action,{title:"Focus Finder",onAction:async()=>{await(0,t.closeMainWindow)(),await d(f)}})]})},n.id)),s&&s.length>1&&(0,r.jsx)(t.List.Item,{title:"Merge all windows into one",icon:t.Icon.Layers,actions:(0,r.jsx)(t.ActionPanel,{children:(0,r.jsx)(t.Action,{title:"Merge All Windows",onAction:P})})},"merge")]})}
