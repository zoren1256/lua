export async function onRequest() {
  return new Response("404 Not Found", { status: 404 });
}
