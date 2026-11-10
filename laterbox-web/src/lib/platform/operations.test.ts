// laterbox-web/src/lib/platform/operations.test.ts
import {test} from 'node:test';
import {strict as assert} from 'node:assert';
import {maintenanceState,type PlatformOperations} from './operations';

const base:PlatformOperations={
 features:{referrals:false,checkout:true,support:true,ai:true},
 maintenanceMode:'off',maintenanceStartsAt:null,maintenanceEndsAt:null,
 maintenanceMessage:'We are improving LaterBox.',updatedAt:null,updatedBy:null,
};
const time=Date.UTC(2026,10,15,12);
test('maintenance stays off by default',()=>{
 assert.equal(maintenanceState(base,time),'off');
});
test('scheduled maintenance counts down until the precise start',()=>{
 const p:PlatformOperations={...base,maintenanceMode:'scheduled',
  maintenanceStartsAt:new Date(time+60000).toISOString(),
  maintenanceEndsAt:new Date(time+120000).toISOString()};
 assert.equal(maintenanceState(p,time),'upcoming');
 assert.equal(maintenanceState(p,time+60000),'active');
 assert.equal(maintenanceState(p,time+120000),'off');
});
test('immediate maintenance switches off automatically at the planned end',()=>{
 const p:PlatformOperations={...base,maintenanceMode:'active',
  maintenanceStartsAt:new Date(time).toISOString(),
  maintenanceEndsAt:new Date(time+3600000).toISOString()};
 assert.equal(maintenanceState(p,time),'active');
 assert.equal(maintenanceState(p,time+3600001),'off');
});
test('maintenance mode off overrides stale future timestamps',()=>{
 assert.equal(maintenanceState({...base,maintenanceMode:'off',maintenanceStartsAt:new Date(time).toISOString(),maintenanceEndsAt:new Date(time+60000).toISOString()},time),'off');
});
