import {config} from './config.js';import {createSessionManager} from './session.js';
export const configured=Boolean(config.url&&config.anonKey);
async function request(path,{method='GET',body,token}={}){if(!configured)throw Error('The workspace service is not configured.');const headers={apikey:config.anonKey,'Content-Type':'application/json'};if(token)headers.Authorization='Bearer '+token;const response=await fetch(config.url.replace(/\/$/,'')+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),cache:'no-store'});const data=await response.json().catch(()=>null);if(!response.ok)throw Error(data?.msg||data?.message||'Request failed ('+response.status+').');return data;}
const sessions=createSessionManager({storage:{getItem:()=>null,setItem:()=>{},removeItem:()=>{}},refresh:refresh_token=>request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token}})});
export async function signIn(email,password){const s=await request('/auth/v1/token?grant_type=password',{method:'POST',body:{email,password}});sessions.set(s);return s.user;}
export async function register(email,password){return request('/auth/v1/signup',{method:'POST',body:{email,password}});}
export async function restoreSession(){if(!configured||!sessions.restore())return false;try{const s=await sessions.get();await request('/auth/v1/user',{token:s.access_token});return true;}catch{sessions.clear();return false;}}
export async function signOut(){try{const s=await sessions.get();await request('/auth/v1/logout',{method:'POST',token:s.access_token});}finally{sessions.clear();}}
export async function rpc(name,body={}){const s=await sessions.get();return request('/rest/v1/rpc/'+name,{method:'POST',body,token:s.access_token});}

export async function currentIdentity(){const s=await sessions.get();return request('/auth/v1/user',{token:s.access_token});}
export async function enrollAuthenticator(){const s=await sessions.get();return request('/auth/v1/factors',{method:'POST',token:s.access_token,body:{factor_type:'totp',issuer:'Opsboard'}});}
export async function verifyAuthenticator(factor,code){if(!/^\d{6}$/.test(code))throw Error('Enter the six-digit code.');const s=await sessions.get();const path='/auth/v1/factors/'+encodeURIComponent(factor);const c=await request(path+'/challenge',{method:'POST',token:s.access_token,body:{}});const result=await request(path+'/verify',{method:'POST',token:s.access_token,body:{challenge_id:c.id,code}});sessions.set({...result,expires_at:result.expires_at??Math.floor(Date.now()/1000)+result.expires_in});}
