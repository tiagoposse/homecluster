{
  kind: "pipeline",
  type: "kubernetes",
  name: "Initialize the platform",
  platform: {
    os: "linux",
    arch: "arm64"
  },
  volumes: [
    {
      name: "certs",
      temp: {}
    },
  ],
  steps: [
    {
      name: "Install certmanager",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        state: "upgrade",
        server: "192.168.178.48",
        details_file: "certmanager/details.yml",
      },
    },
    {
      name: "Create cluster CA",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        server: "192.168.178.48",
        wait: true
      },
      commands: [
        "openssl req -new -x509 -subj \"/C=AT/CN=posse.cluster\" -newkey rsa:2048 -days 3650 -keyout /certs/ca.key -out /certs/ca.pem -nodes",
      ],
      volumes: [
        {
          name: "certs",
          path: "/certs"
        },
      ],
    },
    {
      name: "Create secret with cluster CA",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        server: "192.168.178.48",
        state: 'secret',
        name: 'ca-certificate',
        type: 'generic',
        namespace: 'default',
        args: '--from-file=certificate=/certs/ca.pem --from-file=key=/certs/ca.key'
      },
      volumes: [
        {
          name: "certs",
          path: "/certs"
        },
      ],
    },
    {
      name: "Create vault certificate",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        state: "upgrade",
        server: "192.168.178.48",
        wait: true
      },
      commands: [
        "openssl req -new -out /certs/vault.csr -newkey rsa:2048 -nodes -sha256 -keyout /certs/vault.key -config vault/resources/cert.conf",
        "openssl x509 -req -days 365 -in /certs/vault.csr -CA /certs/ca.pem -CAkey /certs/ca.key -CAcreateserial -out /certs/vault.pem -extfile vault/resources/cert.conf -extensions v3_req"
      ],
      volumes: [
        {
          name: "certs",
          path: "/certs"
        },
      ],
    },
    {
      name: "Create secret with vault certificate",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        server: "192.168.178.48",
        state: 'secret',
        name: 'vault-tls',
        namespace: 'vault',
        type: 'generic',
        args: '--from-file=vault.crt=/certs/vault.pem --from-file=vault.key=/certs/vault.key --from-file=vault.ca=/certs/ca.pem'
      },
      volumes: [
        {
          name: "certs",
          path: "/certs"
        },
      ],
    },
    {
      name: "Install vault",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        state: "upgrade",
        server: "192.168.178.48",
        details_file: "vault/details.yml",
        wait: true
      }
    },
    {
      name: "Setup vault",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        details_file: "vault/details.yml"
      },
      commands: [
        "./vault/resources/setup.sh ./vault/resources/config.yml"
      ],
      volumes: [
        {
          name: "certs",
          path: "/certs"
        },
      ],
    },
    {
      name: "Install museum",
      image: "registry.192.168.178.48.nip.io/cluster-deploy:1.1.4",
      settings: {
        state: "upgrade",
        server: "192.168.178.48",
        server_port: "6443",
        details_file: "museum/details.yml",
      }
    }
  ]
}