import {FeatureGate,StatusBadge,type FeatureState} from './dashboard-kit';import type {CommerceFeature} from '@/lib/commerce/contracts';
export type CommerceModule={feature:CommerceFeature;title:string;state:FeatureState;summary:string;dependency:string};
export function CommerceFoundation({modules}:{modules:CommerceModule[]}){return <div className="dashboard-feature-grid">{modules.map(module=><FeatureGate key={module.feature} title={module.title} state={module.state} reason={module.dependency}><p>{module.summary}</p><StatusBadge tone={module.state==='Blocked'?'danger':module.state==='Preview Only'?'warning':'neutral'}>{module.feature}</StatusBadge></FeatureGate>)}</div>}

