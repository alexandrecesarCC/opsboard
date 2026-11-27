import {rpc} from './api.js';
import {validateState} from './domain.js';
export async function createRemoteStore(organizationId){
 let state=validateState(await rpc('workspace_snapshot',{org:organizationId}));
 return {get state(){return state;},warning:'',async dispatch(action){state=validateState(await rpc('workspace_mutation',{org:organizationId,operation:action.type,payload:action.data}));return state;}};
}
