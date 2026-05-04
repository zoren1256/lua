export async function onRequest(context) {
  const { request, env } = context;
  
  // 取得請求的 User-Agent
  const userAgent = request.headers.get("User-Agent") || "";

  // 1. 阻擋一般瀏覽器 (Chrome, Edge, Safari, 手機瀏覽器等)
  if (userAgent.includes("Mozilla") || userAgent.includes("Chrome") || userAgent.includes("Safari")) {
    // 讓一般人以為這是一個無效的網頁
    return new Response("404 Not Found", { status: 404 });
  }

  // 2. 如果是 Roblox 的 game:HttpGet 或是外掛注入器發出的請求，放行並回傳腳本
  try {
    // 從你 GitHub 上的 main.lua 讀取代碼
    const scriptResponse = await env.ASSETS.fetch(new Request(new URL("/main.lua", request.url)));
    const scriptContent = await scriptResponse.text();
    
    return new Response(scriptContent, {
      headers: { "Content-Type": "text/plain" }
    });
  } catch (err) {
    return new Response("-- 伺服器錯誤", { headers: { "Content-Type": "text/plain" } });
  }
}
