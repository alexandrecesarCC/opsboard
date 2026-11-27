import {config} from './config.js';
export const configured=Boolean(config.url && config.anonKey);
let session=null;
const base=()=>config.url.replace(/\/$/,'');
async function request(path,{method='GET',body,auth=true}={}){
 if(!configured)throw Error('The workspace service is not configured.');
 const headers={apikey:config.anonKey,'Content-Type':'application/json'};
 if(auth&&session)headers.Authorization='Bearer '+session.access_token;
 const response=await fetch(base()+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),cache:'no-store'});
 const data=await response.json().catch(()=>null);
 if(!response.ok)throw Error(data?.msg||data?.message||'Request failed ('+response.status+').');
 return data;
}
export async function signIn(email,password){session=await request('/auth/v1/token?grant_type=password',{method:'POST',body:{email,password},auth:false});return session.user;}
export async function register(email,password){return request('/auth/v1/signup',{method:'POST',body:{email,password},auth:false});}
export async function signOut(){try{if(session)await request('/auth/v1/logout',{method:'POST'});}finally{session=null;}}
export async function rpc(name,body={}){if(!session)throw Error('Sign in first.');if(session.expires_at && session.expires_at*1000<Date.now()+60000){session=await request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token:session.refresh_token},auth:false});}return request('/rest/v1/rpc/'+name,{method:'POST',body});}
