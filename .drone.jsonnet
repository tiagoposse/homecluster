
local components = [
  // 'certmanager',
  'dashboard',
  'drone',
  'drone-monorepo',
  'drone-runner-kube',
  'dyndns',
  'ingress',
  'museum',
  'media',
  'registry',
  'vault'
];

local Pipeline(component) = {
  kind: "pipeline",
  type: "kubernetes",
  name: "Deploy " + component + " via helm",
  metadata: {
    annotations: {
      "autocert.step.sm/name": "drone-build"
    }
  },
  platform: {
    os: "linux",
    arch: "arm64"
  },
  trigger: {
    paths: [
      component + "/**/*.yml"
    ]
  },
  steps: [
    {
      name: "Create vault resources and deploy",
      image: "registry.tiagoposse.com/cluster-droid:0.5.7",
      settings: {
        action: 'upgrade'
      },
      environment: {
        VAULT_ADDR: "https://vault.tiagoposse.com",
        VAULT_CACERT: "/var/run/autocert.step.sm/root.crt",
        DETAILS_PATH: component + "/details.yml"
      },
    }
  ]
};

[ Pipeline(component) for component in components ]