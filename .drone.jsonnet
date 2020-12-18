
local components = [
  // 'certmanager',
  'dashboard',
  'drone',
  'drone-monorepo',
  'drone-runner-kube',
  'drone-vault',
  'dyndns',
  'ingress',
  'museum',
  'media',
  'registry',
  'vault'
];

local Pipeline(component) = {
  kind: "pipeline",
  name: "Deploy " + component + " via helm",
  platform: {
    os: "linux",
    arch: "arm64"
  },
  trigger: {
    paths: [
      component + "/**/*"
    ]
  },
  steps: [
    {
      name: "vault resources",
      image: "registry.192.168.178.48.nip.io/vault-resources:1.0.0",
      settings: {
        vault_addr: ""
      },
      when: {
        paths: [
          "**/*/" + component + "/vault.yml"
        ]
      }
    },
    {
      name: "build",
      image: "registry.192.168.178.48.nip.io/vault-resources:1.0.0",
      settings: {
        state: "upgrade",
        ca_path: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
        server: "192.168.178.48",
        server_port: "6443",
        details_file: component + "details.yml",
        token_path: "/var/run/secrets/kubernetes.io/serviceaccount/token"
      },
      when: {
        paths: [
          "**/*/" + component + "/values.yml"
        ]
      }
    }
  ]
};

[ Pipeline(component) for component in components ]