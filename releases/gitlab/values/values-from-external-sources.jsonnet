local environment = std.extVar('environment');
local chefBaseRole = std.parseJson(std.extVar('chefBaseRole'));
local chefBaseRoleGkms = std.parseJson(std.extVar('chefBaseRoleGkms'));
local gcloudComputeAddresses = std.parseJson(std.extVar('gcloudComputeAddresses'));
local chefBaseDbRedisServerSidekiqRole = (if std.extVar('chefBaseDbRedisServerSidekiqRole') == '' then {} else std.parseJson(std.extVar('chefBaseDbRedisServerSidekiqRole')));
local chefBaseDbRedisServerCacheRole = (if std.extVar('chefBaseDbRedisServerCacheRole') == '' then {} else std.parseJson(std.extVar('chefBaseDbRedisServerCacheRole')));
local chefBaseBeRole = (if std.extVar('chefBaseBeRole') == '' then {} else std.parseJson(std.extVar('chefBaseBeRole')));
local chefBaseBeSidekiqRole = (if std.extVar('chefBaseBeSidekiqRole') == '' then {} else std.parseJson(std.extVar('chefBaseBeSidekiqRole')));
local chefBaseFeRole = (if std.extVar('chefBaseFeRole') == '' then {} else std.parseJson(std.extVar('chefBaseFeRole')));

assert std.isArray(gcloudComputeAddresses);

local convertGitalyEntry(name, value) = {
  name: name,
  port: std.split(value.gitaly_address, ':')[2],
  hostname: std.split(std.split(value.gitaly_address, '/')[2], ':')[0],
};

local findGcloudAddr(y) =
  local a = std.filter(function(x) x.name == y, gcloudComputeAddresses);
  if std.length(a) > 0 then a[0].address
  else '';

local chefRailsConf = chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb['gitlab-rails'];

local valuesFromExternalSources = {
  global: {
    gitaly: {
      external: std.objectValues(std.mapWithKey(convertGitalyEntry, chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb.git_data_dirs)),
    },
    email: {
      from: chefRailsConf.gitlab_email_from,
    },
    appConfig: {
      incomingEmail: {
        address: chefRailsConf.incoming_email_address,
        user: chefRailsConf.incoming_email_email,
      },
      serviceDeskEmail: {
        [if std.objectHas(chefRailsConf, 'service_desk_email_enabled') then 'enabled']: chefRailsConf.service_desk_email_enabled,
        [if std.objectHas(chefRailsConf, 'service_desk_email_address') then 'address']: chefRailsConf.service_desk_email_address,
        [if std.objectHas(chefRailsConf, 'service_desk_email_email') then 'user']: chefRailsConf.service_desk_email_email,
      },
      lfs: {
        enabled: chefRailsConf.lfs_object_store_enabled,
        bucket: chefRailsConf.lfs_object_store_remote_directory,
      },
      artifacts: {
        enabled: chefRailsConf.artifacts_object_store_enabled,
        bucket: chefRailsConf.artifacts_object_store_remote_directory,
      },
      uploads: {
        enabled: chefRailsConf.uploads_object_store_enabled,
        bucket: chefRailsConf.uploads_object_store_remote_directory,
      },
      packages: {
        enabled: chefRailsConf.packages_object_store_enabled,
        bucket: chefRailsConf.packages_object_store_remote_directory,
      },
      externalDiffs: {
        enabled: chefRailsConf.external_diffs_object_store_enabled,
        bucket: chefRailsConf.external_diffs_object_store_remote_directory,
      },
      terraformState: {
        enabled: chefRailsConf.terraform_state_object_store_enabled,
        bucket: chefRailsConf.terraform_state_object_store_remote_directory,
      },
      dependencyProxy: {
        enabled: chefRailsConf.dependency_proxy_object_store_enabled,
        bucket: chefRailsConf.dependency_proxy_object_store_remote_directory,
      },
      omniauth: {
        enabled: chefRailsConf.omniauth_enabled,
        blockAutoCreatedUsers: chefRailsConf.omniauth_block_auto_created_users,
      },
      cron_jobs: {
        pipeline_schedule_worker: {
          cron: chefRailsConf.pipeline_schedule_worker_cron,
        },
        schedule_migrate_external_diffs_worker: {
          [if std.objectHas(chefRailsConf, 'schedule_migrate_external_diffs_worker_cron') then 'cron']: chefRailsConf.schedule_migrate_external_diffs_worker_cron,
        },
      },
      sentry: {
        enabled: chefRailsConf.sentry_enabled,
        dsn: chefRailsConf.sentry_dsn,
        [if std.objectHas(chefRailsConf, 'sentry_clientside_dsn') then 'clientside_dsn']: chefRailsConf.sentry_clientside_dsn,
      },
    },
    hosts: {
      externalIP: findGcloudAddr('nginx-gke-' + environment),
      registry: {
        name: std.strReplace(chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb.registry_external_url, 'https://', ''),
      },
    },
    pages: {
      host: std.strReplace(chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb.pages_external_url, 'https://', ''),
    },
    psql: {
      host: chefRailsConf.db_host,
      port: chefRailsConf.db_port,
      username: chefRailsConf.db_username,
    },
    smtp: {
      address: chefRailsConf.smtp_address,
      authentication: chefRailsConf.smtp_authentication,
      domain: chefRailsConf.smtp_domain,
      starttls_auto: chefRailsConf.smtp_enable_starttls_auto,
      user_name: chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'].smtp_user_name,
    },
    redis: if std.objectHas(chefBaseDbRedisServerSidekiqRole, 'override_attributes') then {
      host: chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb.redis.master_name,
      sentinels: chefRailsConf.redis_sentinels,
      cache: {
        host: chefBaseDbRedisServerCacheRole.override_attributes['omnibus-gitlab'].gitlab_rb.redis.master_name,
        sentinels: chefRailsConf.redis_cache_sentinels,
        password: {
          enabled: 'true',
          secret: 'gitlab-redis-credential-v1',
          key: 'secret',
        },
      },
      sharedState: {
        host: chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb.redis.master_name,
        sentinels: chefRailsConf.redis_sentinels,
        password: {
          enabled: 'true',
          secret: 'gitlab-redis-credential-v1',
          key: 'secret',
        },
      },
      queues: {
        host: chefBaseDbRedisServerSidekiqRole.override_attributes['omnibus-gitlab'].gitlab_rb.redis.master_name,
        sentinels: chefRailsConf.redis_queues_sentinels,
        password: {
          enabled: 'true',
          secret: 'gitlab-redis-credential-v1',
          key: 'secret',
        },
      },
    } else {
      host: chefRailsConf.redis_host,
      port: chefRailsConf.redis_port,
      password: {
        enabled: std.objectHas(chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'], 'redis_password'),
      },
    },
  },
  registry: {
    service: {
      loadBalancerIP: findGcloudAddr('registry-gke-' + environment),
    },
  },
  gitlab: {
    'gitlab-shell': {
      service: {
        type: 'LoadBalancer',
        loadBalancerIP: findGcloudAddr('ssh-gke-' + environment),
        annotations: {
          'cloud.google.com/load-balancer-type': 'Internal',
        },
      },
    },
    webservice: {
      extraEnv: {
        [if std.objectHas(chefBaseFeRole.default_attributes['omnibus-gitlab'], 'user_ratelimit_bypasses') then 'GITLAB_THROTTLE_USER_ALLOW_LIST']: std.join(",", std.objectFields(chefBaseFeRole.default_attributes['omnibus-gitlab'].user_ratelimit_bypasses)),
        // THIS IS SENSITIVE INFORMATION
        // GITLAB_UPLOAD_API_ALLOWLIST: chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'].env.GITLAB_UPLOAD_API_ALLOWLIST,
        // GITLAB_GRAFANA_API_KEY: chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'].env.GITLAB_GRAFANA_API_KEY,
        // SUBSCRIPTION_PORTAL_ADMIN_EMAIL: chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'].env.SUBSCRIPTION_PORTAL_ADMIN_EMAIL,
        // SUBSCRIPTION_PORTAL_ADMIN_TOKEN: chefBaseRoleGkms['omnibus-gitlab'].gitlab_rb['gitlab-rails'].env.SUBSCRIPTION_PORTAL_ADMIN_TOKEN,
      },
      rack_attack: {
        git_basic_auth: {
          enabled: chefRailsConf.rack_attack_git_basic_auth.enabled,
          ip_whitelist: chefRailsConf.rack_attack_git_basic_auth.ip_whitelist,
          maxretry: 30,
          findtime: 180,
          bantime: 3600,
        },
      },
      workhorse: {
        [if std.objectHas(chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb['gitlab-workhorse'], 'env') then 'sentryDSN']: chefBaseRole.default_attributes['omnibus-gitlab'].gitlab_rb['gitlab-workhorse'].env.GITLAB_WORKHORSE_SENTRY_DSN,
      },
      deployments: {
        git: {
          service: {
            loadBalancerIP: findGcloudAddr('git-https-gke-' + environment),
          },
        },
        websockets: {
          [if findGcloudAddr('websockets-gke-' + environment) != '' then 'service']: {
            loadBalancerIP: findGcloudAddr('websockets-gke-' + environment),
            type: 'LoadBalancer',
            loadBalancerSourceRanges: [
              '10.0.0.0/8',
            ],
          },
        },
      },
    },
    sidekiq: {
      psql: {
        [if std.objectHas(chefBaseBeRole.default_attributes, 'omnibus-gitlab') then 'database']: chefBaseBeRole.default_attributes['omnibus-gitlab'].gitlab_rb['gitlab-rails'].db_database,
        host: chefBaseBeSidekiqRole.default_attributes['omnibus-gitlab'].gitlab_rb['gitlab-rails'].db_host,
      },
    },
  },
};
std.manifestYamlDoc(valuesFromExternalSources)
