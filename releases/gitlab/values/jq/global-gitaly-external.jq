.default_attributes."omnibus-gitlab".gitlab_rb.git_data_dirs | to_entries | map_values({ name: .key, port: .value.gitaly_address | split(":")[2], hostname: .value.gitaly_address | match("(?:tcp|tls)://(.*):").captures[0].string, tlsEnabled: .value.gitaly_address | test("tls://") })
