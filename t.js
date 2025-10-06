// ==UserScript==
// @name         Funlink DUMB
// @namespace    https://w88vt.com
// @version      1.1
// @match        https://*/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(async function () {
    'use strict';

    const AP_BASE = "https://public.funlink.io/api/code/";
    function genVid() {
        return ([10000000] + -1000 + -4000 + -8000 + -100000000000)
            .replace(/[018]/g, a => (a ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> a / 4).toString(16));
    }
    function setCookie(name, value, minutes) {
        const d = new Date();
        d.setTime(d.getTime() + minutes * 60 * 1000);
        document.cookie = `${name}=${value};expires=${d.toUTCString()};path=/`;
    }
    function getCookie(name) {
        const pref = name + "=";
        const parts = decodeURIComponent(document.cookie).split(";");
        for (let p of parts) {
            p = p.trim();
            if (p.indexOf(pref) === 0) return p.substring(pref.length);
        }
        return "";
    }

    async function optionData(url, rid) {
        return await fetch(url, {
            method: "OPTIONS",
            cache: "no-cache",
            headers: { rid }
        });
    }

    async function postData(url, data, rid) {
        return await fetch(url, {
            method: "POST",
            cache: "no-cache",
            headers: {
                "Content-Type": "application/json",
                rid
            },
            body: JSON.stringify(data)
        });
    }

    try {
        const vid = genVid();
        setCookie("vid", vid, 6);
        console.log("[funlink-tester] vid ->", vid);

        const optResp = await optionData(AP_BASE + "ch", vid);
        const Cd = optResp.headers.get("Cd");
        const Ms = optResp.headers.get("Ms");
        const Msc = optResp.headers.get("Msc");
        console.log("[funlink-tester] headers Cd,Ms,Msc =", Cd, Ms, Msc);

        const payload = {
            screen: `${screen.width} × ${screen.height}`,
            browser_name: "Chrome",
            browser_version: navigator.userAgent.match(/Chrome\/([0-9.]+)/)?.[1] || "",
            browser_major_version: (navigator.userAgent.match(/Chrome\/([0-9]+)/)?.[1] || ""),
            is_mobile: /Mobi|Android/i.test(navigator.userAgent),
            os_name: "Windows",
            os_version: "10",
            is_cookies: !!getCookie("vid"),
            href: window.location.href,
            user_agent: navigator.userAgent,
            hostname: "https://" + window.location.hostname
        };

        console.log("[funlink-tester] Đang chờ 60s trước khi gọi /code...");
        await new Promise(resolve => setTimeout(resolve, 60000));

        const postResp = await postData(AP_BASE + "code", payload, vid);

        let postJson;
        try {
            postJson = await postResp.json();
        } catch (err) {
            postJson = { _error_parsing_json: true, status: postResp.status, text: await postResp.text() };
        }

        console.log("[funlink-tester] POST response:", postResp, postJson);

        const box = document.createElement("div");
        box.style = "position:fixed;right:10px;bottom:10px;z-index:999999;background:rgba(0,0,0,0.8);color:#fff;padding:10px;border-radius:6px;font-size:13px;max-width:320px;";
        box.innerHTML = `<b>funlink tester</b><br>OPTIONS Cd=${Cd} Ms=${Ms} Msc=${Msc}<br>POST status: ${postResp.status}<pre style="white-space:pre-wrap;max-height:200px;overflow:auto;margin-top:6px;">${JSON.stringify(postJson, null, 2)}</pre>`;
        const closeBtn = document.createElement("button");
        closeBtn.textContent = "×";
        closeBtn.style = "position:absolute;right:6px;top:4px;background:transparent;border:0;color:#fff;font-weight:bold;font-size:14px;cursor:pointer;";
        closeBtn.onclick = () => box.remove();
        box.appendChild(closeBtn);
        document.body.appendChild(box);

    } catch (err) {
        console.error("[funlink-tester] error:", err);
        alert("Error when calling funlink API — check console.");
    }

})();
