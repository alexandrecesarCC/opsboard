export function serialQueue(){let tail=Promise.resolve();return function run(work){const job=tail.then(work);tail=job.catch(()=>{});return job;};}
