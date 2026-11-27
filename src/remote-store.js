import {rpc} from './api.js';
import {validateState} from './domain.js';
import {serialQueue} from './queue.js';
export async function createRemoteStore(organizationId,call=rpc){let state=validateState(await call('workspace_snapshot',{org:organizationId}));const run=serialQueue();return {get state(){return state;},warning:'',dispatch(action){return run(async()=>{state=validateState(await call('workspace_mutation',{org:organizationId,operation:action.type,payload:action.data}));return state;});}};}
