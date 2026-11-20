
const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{"content-type":"application/json; charset=utf-8","cache-control":"no-store"}});
async function cached(env,key,ttl,fn){if(env.SA_CACHE){const hit=await env.SA_CACHE.get(key,"json");if(hit)return hit;}const value=await fn();if(env.SA_CACHE&&value)await env.SA_CACHE.put(key,JSON.stringify(value),{expirationTtl:ttl});return value;}
function safeId(){return crypto.randomUUID();}
export default {
 async fetch(request,env){
  const url=new URL(request.url);
  if(url.pathname==="/api/search"&&request.method==="GET"){
   const type=url.searchParams.get("type"),q=(url.searchParams.get("q")||"").trim().slice(0,160);
   if(!q)return json({results:[]});
   const key="search:v1:"+type+":"+q.toLowerCase();
   try{
    const data=await cached(env,key,1800,async()=>{
     if(type==="commons"){
      const api=new URL("https://commons.wikimedia.org/w/api.php");api.searchParams.set("action","query");api.searchParams.set("generator","search");api.searchParams.set("gsrsearch","filetype:bitmap "+q);api.searchParams.set("gsrnamespace","6");api.searchParams.set("gsrlimit","8");api.searchParams.set("prop","imageinfo");api.searchParams.set("iiprop","url|extmetadata");api.searchParams.set("iiurlwidth","520");api.searchParams.set("format","json");
      const r=await fetch(api,{headers:{"User-Agent":"SAAgriAI/1.0 (agricultural knowledge portal)"}});if(!r.ok)throw new Error("Wikimedia API "+r.status);const j=await r.json();
      return {results:Object.values(j.query?.pages||{}).map(p=>({title:p.title,thumb:p.imageinfo?.[0]?.thumburl,url:p.imageinfo?.[0]?.url,author:p.imageinfo?.[0]?.extmetadata?.Artist?.value?.replace(/<[^>]*>/g,"")||"Wikimedia contributor",source:"Wikimedia Commons",attribution:"https://commons.wikimedia.org/wiki/"+encodeURIComponent(p.title)})).filter(x=>x.thumb&&x.url)};
     }
     if(type==="videos"){
      if(!env.YOUTUBE_API_KEY)return {results:[],configured:false};
      const api=new URL("https://www.googleapis.com/youtube/v3/search");api.searchParams.set("part","snippet");api.searchParams.set("q",q);api.searchParams.set("type","video");api.searchParams.set("maxResults","8");api.searchParams.set("regionCode","DZ");api.searchParams.set("relevanceLanguage","ar");api.searchParams.set("videoEmbeddable","true");api.searchParams.set("safeSearch","strict");api.searchParams.set("key",env.YOUTUBE_API_KEY);
      const r=await fetch(api);if(!r.ok)throw new Error("YouTube API "+r.status);const j=await r.json();
      return {configured:true,results:(j.items||[]).map(x=>({videoId:x.id.videoId,title:x.snippet.title,channelTitle:x.snippet.channelTitle,channelId:x.snippet.channelId,channelUrl:"https://www.youtube.com/channel/"+x.snippet.channelId,thumbnail:x.snippet.thumbnails?.medium?.url||x.snippet.thumbnails?.default?.url}))};
     }
     if(type==="images"){
      if(!env.UNSPLASH_ACCESS_KEY)return {results:[],configured:false};
      const api=new URL("https://api.unsplash.com/search/photos");api.searchParams.set("query",q);api.searchParams.set("per_page","8");api.searchParams.set("orientation","landscape");
      const r=await fetch(api,{headers:{Authorization:"Client-ID "+env.UNSPLASH_ACCESS_KEY}});if(!r.ok)throw new Error("Unsplash API "+r.status);const j=await r.json();
      return {configured:true,results:(j.results||[]).map(x=>({title:x.alt_description||x.description||q,thumb:x.urls.small,url:x.urls.full,author:x.user.name,source:"Unsplash",attribution:x.links.html}))};
     }
     return {results:[]};
    });
    return json(data);
   }catch(e){return json({results:[],error:"UPSTREAM_UNAVAILABLE"});}
  }
  if(url.pathname==="/api/search-log"&&request.method==="POST"){
   if(!env.SA_CACHE)return json({ok:false,storage:false},503);
   let body;try{body=await request.json()}catch(e){return json({error:"INVALID_JSON"},400);}
   const query=String(body.query||"").trim().toLowerCase().replace(/\s+/g," ").slice(0,100);
   if(query.length<2)return json({ok:false},400);
   const key="popular:q:"+encodeURIComponent(query);
   const count=Number(await env.SA_CACHE.get(key)||0)+1;
   await env.SA_CACHE.put(key,String(count),{expirationTtl:60*60*24*90});
   const index=await env.SA_CACHE.get("popular:index","json")||[];
   if(!index.includes(key))index.unshift(key);
   await env.SA_CACHE.put("popular:index",JSON.stringify(index.slice(0,100)),{expirationTtl:60*60*24*90});
   return json({ok:true});
  }
  if(url.pathname==="/api/popular"&&request.method==="GET"){
   if(!env.SA_CACHE)return json({results:[]});
   const keys=await env.SA_CACHE.get("popular:index","json")||[];
   const results=await Promise.all(keys.map(async key=>({query:decodeURIComponent(key.slice("popular:q:".length)),count:Number(await env.SA_CACHE.get(key)||0)})));
   return json({results:results.filter(x=>x.count>0).sort((a,b)=>b.count-a.count).slice(0,8)});
  }
  if(url.pathname==="/api/questions"&&request.method==="POST"){
   if(!env.SA_CACHE)return json({error:"STORAGE_NOT_CONFIGURED"},503);
   let body;try{body=await request.json()}catch(e){return json({error:"INVALID_JSON"},400);}
   const question=String(body.question||"").trim().slice(0,1200);if(question.length<5)return json({error:"QUESTION_TOO_SHORT"},400);
   const ip=request.headers.get("CF-Connecting-IP")||"unknown";const rateKey="question-rate:"+ip;const rate=Number(await env.SA_CACHE.get(rateKey)||0);if(rate>=5)return json({error:"RATE_LIMITED"},429);await env.SA_CACHE.put(rateKey,String(rate+1),{expirationTtl:600});
   const record={id:safeId(),question,createdAt:new Date().toISOString(),status:"new"};
   const index=await env.SA_CACHE.get("questions:index","json")||[];index.unshift(record.id);
   await env.SA_CACHE.put("question:"+record.id,JSON.stringify(record),{expirationTtl:60*60*24*180});
   await env.SA_CACHE.put("questions:index",JSON.stringify(index.slice(0,500)),{expirationTtl:60*60*24*180});
   return json({ok:true,id:record.id},201);
  }
  if(url.pathname==="/api/questions"&&request.method==="GET"){
   const auth=request.headers.get("authorization")||"";
   if(!env.ADMIN_TOKEN||auth!=="Bearer "+env.ADMIN_TOKEN)return json({error:"UNAUTHORIZED"},401);
   if(!env.SA_CACHE)return json({error:"STORAGE_NOT_CONFIGURED"},503);
   const ids=await env.SA_CACHE.get("questions:index","json")||[];
   const items=(await Promise.all(ids.slice(0,200).map(id=>env.SA_CACHE.get("question:"+id,"json")))).filter(Boolean);
   return json({items});
  }
  if(url.pathname.startsWith("/api/"))return json({error:"NOT_FOUND"},404);
  return env.ASSETS.fetch(request);
 }
};