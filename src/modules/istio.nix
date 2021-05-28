# This file was generated with kubenix k8s generator, do not edit
{ lib, config, ... }:

with lib;
let
  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo = coercedType: coerceFunc: finalType:
      mkOptionType rec {
        name = "coercedTo";
        description = "${finalType.description} or ${coercedType.description}";
        check = x: finalType.check x || coercedType.check x;
        merge = loc: defs:
          let
            coerceVal = val:
              if finalType.check val then val
              else
                let
                  coerced = coerceFunc val;
                in
                assert finalType.check coerced; coerced;

          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        getSubOptions = finalType.getSubOptions;
        getSubModules = finalType.getSubModules;
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // { wrapped = finalType; };
      };
  };

  mkOptionDefault = mkOverride 1001;

  extraOptions = {
    kubenix = { };
  };

  mergeValuesByKey = mergeKey: values:
    listToAttrs (map
      (value: nameValuePair
        (
          if isAttrs value.${mergeKey}
          then toString value.${mergeKey}.content
          else (toString value.${mergeKey})
        )
        value)
      values);

  submoduleOf = ref: types.submodule ({ name, ... }: {
    options = definitions."${ref}".options;
    config = definitions."${ref}".config;
  });

  submoduleWithMergeOf = ref: mergeKey: types.submodule ({ name, ... }:
    let
      convertName = name:
        if definitions."${ref}".options.${mergeKey}.type == types.int
        then toInt name
        else name;
    in
    {
      options = definitions."${ref}".options;
      config = definitions."${ref}".config // {
        ${mergeKey} = mkOverride 1002 (convertName name);
      };
    });

  submoduleForDefinition = ref: resource: kind: group: version:
    types.submodule ({ name, ... }: {
      options = definitions."${ref}".options // extraOptions;
      config = mkMerge ([
        definitions."${ref}".config
        {
          kind = mkOptionDefault kind;
          apiVersion = mkOptionDefault version;

          # metdata.name cannot use option default, due deep config
          metadata.name = mkOptionDefault name;
        }
      ] ++ (config.defaults.${resource} or [ ])
      ++ (config.defaults.all or [ ]));
    });

  coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: (types.coercedTo
    (types.listOf (submoduleOf ref))
    (mergeValuesByKey mergeKey)
    (types.attrsOf (submoduleWithMergeOf ref mergeKey))
  );

  definitions = {

    "google_rpc_Status" = {
      options = {
        "code" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "details" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "protobuf_types_Any")));
        };

        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "code" = mkOverride 1002 null;

        "details" = mkOverride 1002 null;

        "message" = mkOverride 1002 null;
      };
    };

    "istio_adapter_bypass_Params" = {
      options = {
        "backendAddress" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "params" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Any"));
        };

        "sessionBased" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "backendAddress" = mkOverride 1002 null;

        "params" = mkOverride 1002 null;

        "sessionBased" = mkOverride 1002 null;
      };
    };

    "istio_adapter_circonus_Params" = {
      options = {
        "metrics" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_circonus_Params_MetricInfo")));
        };

        "submissionInterval" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "submissionUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "metrics" = mkOverride 1002 null;

        "submissionInterval" = mkOverride 1002 null;

        "submissionUrl" = mkOverride 1002 null;
      };
    };

    "istio_adapter_circonus_Params_MetricInfo" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "type" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "type" = mkOverride 1002 null;
      };
    };

    "istio_adapter_denier_Params" = {
      options = {
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "google_rpc_Status"));
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "validUseCount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "status" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;

        "validUseCount" = mkOverride 1002 null;
      };
    };

    "istio_adapter_dogstatsd_Params" = {
      options = {
        "address" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "bufferLength" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "globalTags" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "metrics" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "prefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sampleRate" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "address" = mkOverride 1002 null;

        "bufferLength" = mkOverride 1002 null;

        "globalTags" = mkOverride 1002 null;

        "metrics" = mkOverride 1002 null;

        "prefix" = mkOverride 1002 null;

        "sampleRate" = mkOverride 1002 null;
      };
    };

    "istio_adapter_dogstatsd_Params_MetricInfo" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "tags" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "type" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "tags" = mkOverride 1002 null;

        "type" = mkOverride 1002 null;
      };
    };

    "istio_adapter_fluentd_Params" = {
      options = {
        "address" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "integerDuration" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "address" = mkOverride 1002 null;

        "integerDuration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_kubernetesenv_Params" = {
      options = {
        "cacheRefreshDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "kubeconfigPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "cacheRefreshDuration" = mkOverride 1002 null;

        "kubeconfigPath" = mkOverride 1002 null;
      };
    };

    "istio_adapter_list_Params" = {
      options = {
        "blacklist" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "cachingInterval" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "cachingUseCount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "entryType" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "overrides" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "providerUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "refreshInterval" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "ttl" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "blacklist" = mkOverride 1002 null;

        "cachingInterval" = mkOverride 1002 null;

        "cachingUseCount" = mkOverride 1002 null;

        "entryType" = mkOverride 1002 null;

        "overrides" = mkOverride 1002 null;

        "providerUrl" = mkOverride 1002 null;

        "refreshInterval" = mkOverride 1002 null;

        "ttl" = mkOverride 1002 null;
      };
    };

    "istio_adapter_memquota_Params" = {
      options = {
        "minDeduplicationDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "quotas" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_memquota_Params_Quota")));
        };
      };

      config = {
        "minDeduplicationDuration" = mkOverride 1002 null;

        "quotas" = mkOverride 1002 null;
      };
    };

    "istio_adapter_memquota_Params_Override" = {
      options = {
        "dimensions" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "maxAmount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "dimensions" = mkOverride 1002 null;

        "maxAmount" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_memquota_Params_Quota" = {
      options = {
        "maxAmount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "overrides" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_memquota_Params_Override")));
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "maxAmount" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "overrides" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_opa_Params" = {
      options = {
        "checkMethod" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "failClose" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "policy" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "checkMethod" = mkOverride 1002 null;

        "failClose" = mkOverride 1002 null;

        "policy" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params" = {
      options = {
        "metrics" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_prometheus_Params_MetricInfo")));
        };

        "metricsExpirationPolicy" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_prometheus_Params_MetricsExpirationPolicy"));
        };
      };

      config = {
        "metrics" = mkOverride 1002 null;

        "metricsExpirationPolicy" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo" = {
      options = {
        "buckets" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition"));
        };

        "description" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "instanceName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "kind" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "labelNames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "namespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "buckets" = mkOverride 1002 null;

        "description" = mkOverride 1002 null;

        "instanceName" = mkOverride 1002 null;

        "kind" = mkOverride 1002 null;

        "labelNames" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "namespace" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition" = {
      options = {
        "definition" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "definition" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Explicit" = {
      options = {
        "bounds" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.int));
        };
      };

      config = {
        "bounds" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_ExplicitBuckets" = {
      options = {
        "explicitBuckets" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Explicit"));
        };
      };

      config = {
        "explicitBuckets" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Exponential" = {
      options = {
        "growthFactor" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "numFiniteBuckets" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "scale" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "growthFactor" = mkOverride 1002 null;

        "numFiniteBuckets" = mkOverride 1002 null;

        "scale" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_ExponentialBuckets" = {
      options = {
        "exponentialBuckets" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Exponential"));
        };
      };

      config = {
        "exponentialBuckets" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Linear" = {
      options = {
        "numFiniteBuckets" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "offset" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "width" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "numFiniteBuckets" = mkOverride 1002 null;

        "offset" = mkOverride 1002 null;

        "width" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_LinearBuckets" = {
      options = {
        "linearBuckets" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_prometheus_Params_MetricInfo_BucketsDefinition_Linear"));
        };
      };

      config = {
        "linearBuckets" = mkOverride 1002 null;
      };
    };

    "istio_adapter_prometheus_Params_MetricsExpirationPolicy" = {
      options = {
        "expiryCheckIntervalDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "metricsExpiryDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "expiryCheckIntervalDuration" = mkOverride 1002 null;

        "metricsExpiryDuration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_rbac_Params" = {
      options = {
        "cacheDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "configStoreUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "cacheDuration" = mkOverride 1002 null;

        "configStoreUrl" = mkOverride 1002 null;
      };
    };

    "istio_adapter_redisquota_Params" = {
      options = {
        "connectionPoolSize" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "quotas" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_redisquota_Params_Quota")));
        };

        "redisServerUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "connectionPoolSize" = mkOverride 1002 null;

        "quotas" = mkOverride 1002 null;

        "redisServerUrl" = mkOverride 1002 null;
      };
    };

    "istio_adapter_redisquota_Params_Override" = {
      options = {
        "dimensions" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "maxAmount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "dimensions" = mkOverride 1002 null;

        "maxAmount" = mkOverride 1002 null;
      };
    };

    "istio_adapter_redisquota_Params_Quota" = {
      options = {
        "bucketDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "maxAmount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "overrides" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_redisquota_Params_Override")));
        };

        "rateLimitAlgorithm" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "bucketDuration" = mkOverride 1002 null;

        "maxAmount" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "overrides" = mkOverride 1002 null;

        "rateLimitAlgorithm" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_servicecontrol_GcpServiceSetting" = {
      options = {
        "googleServiceName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "meshServiceName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "quotas" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_servicecontrol_Quota")));
        };
      };

      config = {
        "googleServiceName" = mkOverride 1002 null;

        "meshServiceName" = mkOverride 1002 null;

        "quotas" = mkOverride 1002 null;
      };
    };

    "istio_adapter_servicecontrol_Params" = {
      options = {
        "credentialPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "runtimeConfig" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_servicecontrol_RuntimeConfig"));
        };

        "serviceConfigs" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_servicecontrol_GcpServiceSetting")));
        };
      };

      config = {
        "credentialPath" = mkOverride 1002 null;

        "runtimeConfig" = mkOverride 1002 null;

        "serviceConfigs" = mkOverride 1002 null;
      };
    };

    "istio_adapter_servicecontrol_Quota" = {
      options = {
        "expiration" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };

        "googleQuotaMetricName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "expiration" = mkOverride 1002 null;

        "googleQuotaMetricName" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;
      };
    };

    "istio_adapter_servicecontrol_RuntimeConfig" = {
      options = {
        "checkCacheSize" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "checkResultExpiration" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };
      };

      config = {
        "checkCacheSize" = mkOverride 1002 null;

        "checkResultExpiration" = mkOverride 1002 null;
      };
    };

    "istio_adapter_signalfx_Params" = {
      options = {
        "accessToken" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "datapointInterval" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "ingestUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "metrics" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_adapter_signalfx_Params_MetricConfig")));
        };
      };

      config = {
        "accessToken" = mkOverride 1002 null;

        "datapointInterval" = mkOverride 1002 null;

        "ingestUrl" = mkOverride 1002 null;

        "metrics" = mkOverride 1002 null;
      };
    };

    "istio_adapter_signalfx_Params_MetricConfig" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "type" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "type" = mkOverride 1002 null;
      };
    };

    "istio_adapter_solarwinds_Params" = {
      options = {
        "appopticsAccessToken" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "appopticsBatchSize" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "logs" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "metrics" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "papertrailLocalRetentionDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "papertrailUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "appopticsAccessToken" = mkOverride 1002 null;

        "appopticsBatchSize" = mkOverride 1002 null;

        "logs" = mkOverride 1002 null;

        "metrics" = mkOverride 1002 null;

        "papertrailLocalRetentionDuration" = mkOverride 1002 null;

        "papertrailUrl" = mkOverride 1002 null;
      };
    };

    "istio_adapter_solarwinds_Params_LogInfo" = {
      options = {
        "payloadTemplate" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "payloadTemplate" = mkOverride 1002 null;
      };
    };

    "istio_adapter_solarwinds_Params_MetricInfo" = {
      options = {
        "labelNames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "labelNames" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params" = {
      options = {
        "creds" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "endpoint" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "logInfo" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "metricInfo" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "projectId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "pushInterval" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "trace" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_stackdriver_Params_Trace"));
        };
      };

      config = {
        "creds" = mkOverride 1002 null;

        "endpoint" = mkOverride 1002 null;

        "logInfo" = mkOverride 1002 null;

        "metricInfo" = mkOverride 1002 null;

        "projectId" = mkOverride 1002 null;

        "pushInterval" = mkOverride 1002 null;

        "trace" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_ApiKey" = {
      options = {
        "apiKey" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "apiKey" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_AppCredentials" = {
      options = {
        "appCredentials" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "appCredentials" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_LogInfo" = {
      options = {
        "httpMapping" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_stackdriver_Params_LogInfo_HttpRequestMapping"));
        };

        "labelNames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "payloadTemplate" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sinkInfo" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_stackdriver_Params_LogInfo_SinkInfo"));
        };
      };

      config = {
        "httpMapping" = mkOverride 1002 null;

        "labelNames" = mkOverride 1002 null;

        "payloadTemplate" = mkOverride 1002 null;

        "sinkInfo" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_LogInfo_HttpRequestMapping" = {
      options = {
        "latency" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "localIp" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "method" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "referer" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "remoteIp" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "requestSize" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "responseSize" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "url" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "userAgent" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "latency" = mkOverride 1002 null;

        "localIp" = mkOverride 1002 null;

        "method" = mkOverride 1002 null;

        "referer" = mkOverride 1002 null;

        "remoteIp" = mkOverride 1002 null;

        "requestSize" = mkOverride 1002 null;

        "responseSize" = mkOverride 1002 null;

        "status" = mkOverride 1002 null;

        "url" = mkOverride 1002 null;

        "userAgent" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_LogInfo_SinkInfo" = {
      options = {
        "UniqueWriterIdentity" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "UpdateDestination" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "UpdateFilter" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "UpdateIncludeChildren" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "destination" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "filter" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "id" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "UniqueWriterIdentity" = mkOverride 1002 null;

        "UpdateDestination" = mkOverride 1002 null;

        "UpdateFilter" = mkOverride 1002 null;

        "UpdateIncludeChildren" = mkOverride 1002 null;

        "destination" = mkOverride 1002 null;

        "filter" = mkOverride 1002 null;

        "id" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_MetricInfo" = {
      options = {
        "buckets" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_adapter_stackdriver_Params_MetricInfo_BucketsDefinition"));
        };

        "kind" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "metricType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "value" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "buckets" = mkOverride 1002 null;

        "kind" = mkOverride 1002 null;

        "metricType" = mkOverride 1002 null;

        "value" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_MetricInfo_BucketsDefinition" = {
      options = {
        "definition" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "definition" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_ServiceAccountPath" = {
      options = {
        "serviceAccountPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "serviceAccountPath" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stackdriver_Params_Trace" = {
      options = {
        "sampleProbability" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "sampleProbability" = mkOverride 1002 null;
      };
    };

    "istio_adapter_statsd_Params" = {
      options = {
        "address" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "flushBytes" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "flushDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "metrics" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "prefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "samplingRate" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "address" = mkOverride 1002 null;

        "flushBytes" = mkOverride 1002 null;

        "flushDuration" = mkOverride 1002 null;

        "metrics" = mkOverride 1002 null;

        "prefix" = mkOverride 1002 null;

        "samplingRate" = mkOverride 1002 null;
      };
    };

    "istio_adapter_statsd_Params_MetricInfo" = {
      options = {
        "nameTemplate" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "type" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "nameTemplate" = mkOverride 1002 null;

        "type" = mkOverride 1002 null;
      };
    };

    "istio_adapter_stdio_Params" = {
      options = {
        "logStream" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "maxDaysBeforeRotation" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "maxMegabytesBeforeRotation" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "maxRotatedFiles" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "metricLevel" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "outputAsJson" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "outputLevel" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "outputPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "severityLevels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };
      };

      config = {
        "logStream" = mkOverride 1002 null;

        "maxDaysBeforeRotation" = mkOverride 1002 null;

        "maxMegabytesBeforeRotation" = mkOverride 1002 null;

        "maxRotatedFiles" = mkOverride 1002 null;

        "metricLevel" = mkOverride 1002 null;

        "outputAsJson" = mkOverride 1002 null;

        "outputLevel" = mkOverride 1002 null;

        "outputPath" = mkOverride 1002 null;

        "severityLevels" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_Jwt" = {
      options = {
        "audiences" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "issuer" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "jwksUri" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "jwtHeaders" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "jwtParams" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "audiences" = mkOverride 1002 null;

        "issuer" = mkOverride 1002 null;

        "jwksUri" = mkOverride 1002 null;

        "jwtHeaders" = mkOverride 1002 null;

        "jwtParams" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_MutualTls" = {
      options = {
        "allowTls" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "allowTls" = mkOverride 1002 null;

        "mode" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_OriginAuthenticationMethod" = {
      options = {
        "jwt" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_authentication_v1alpha1_Jwt"));
        };
      };

      config = {
        "jwt" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PeerAuthenticationMethod" = {
      options = {
        "params" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "params" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PeerAuthenticationMethod_Jwt" = {
      options = {
        "jwt" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_authentication_v1alpha1_Jwt"));
        };
      };

      config = {
        "jwt" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PeerAuthenticationMethod_Mtls" = {
      options = {
        "mtls" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_authentication_v1alpha1_MutualTls"));
        };
      };

      config = {
        "mtls" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_Policy" = {
      options = {
        "originIsOptional" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "origins" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_authentication_v1alpha1_OriginAuthenticationMethod")));
        };

        "peerIsOptional" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "peers" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_authentication_v1alpha1_PeerAuthenticationMethod")));
        };

        "principalBinding" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "targets" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_authentication_v1alpha1_TargetSelector")));
        };
      };

      config = {
        "originIsOptional" = mkOverride 1002 null;

        "origins" = mkOverride 1002 null;

        "peerIsOptional" = mkOverride 1002 null;

        "peers" = mkOverride 1002 null;

        "principalBinding" = mkOverride 1002 null;

        "targets" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PortSelector" = {
      options = {
        "port" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "port" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PortSelector_Name" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_PortSelector_Number" = {
      options = {
        "number" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "number" = mkOverride 1002 null;
      };
    };

    "istio_authentication_v1alpha1_TargetSelector" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "ports" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_authentication_v1alpha1_PortSelector")));
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "ports" = mkOverride 1002 null;
      };
    };

    "istio_mesh_v1alpha1_MeshConfig" = {
      options = {
        "accessLogFile" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "authPolicy" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "connectTimeout" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "defaultConfig" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mesh_v1alpha1_ProxyConfig"));
        };

        "disablePolicyChecks" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "enableClientSidePolicyCheck" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "enableTracing" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "ingressClass" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "ingressControllerMode" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "ingressService" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "mixerAddress" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "mixerCheckServer" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "mixerReportServer" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "outboundTrafficPolicy" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mesh_v1alpha1_MeshConfig_OutboundTrafficPolicy"));
        };

        "policyCheckFailOpen" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "proxyHttpPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "proxyListenPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "rdsRefreshDelay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "sdsRefreshDelay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "sdsUdsPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessLogFile" = mkOverride 1002 null;

        "authPolicy" = mkOverride 1002 null;

        "connectTimeout" = mkOverride 1002 null;

        "defaultConfig" = mkOverride 1002 null;

        "disablePolicyChecks" = mkOverride 1002 null;

        "enableClientSidePolicyCheck" = mkOverride 1002 null;

        "enableTracing" = mkOverride 1002 null;

        "ingressClass" = mkOverride 1002 null;

        "ingressControllerMode" = mkOverride 1002 null;

        "ingressService" = mkOverride 1002 null;

        "mixerAddress" = mkOverride 1002 null;

        "mixerCheckServer" = mkOverride 1002 null;

        "mixerReportServer" = mkOverride 1002 null;

        "outboundTrafficPolicy" = mkOverride 1002 null;

        "policyCheckFailOpen" = mkOverride 1002 null;

        "proxyHttpPort" = mkOverride 1002 null;

        "proxyListenPort" = mkOverride 1002 null;

        "rdsRefreshDelay" = mkOverride 1002 null;

        "sdsRefreshDelay" = mkOverride 1002 null;

        "sdsUdsPath" = mkOverride 1002 null;
      };
    };

    "istio_mesh_v1alpha1_MeshConfig_OutboundTrafficPolicy" = {
      options = {
        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
      };
    };

    "istio_mesh_v1alpha1_ProxyConfig" = {
      options = {
        "availabilityZone" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "binaryPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "concurrency" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "configPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "connectTimeout" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "controlPlaneAuthPolicy" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "customConfigFile" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "discoveryAddress" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "discoveryRefreshDelay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "drainDuration" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "interceptionMode" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "parentShutdownDuration" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_duration_Duration"));
        };

        "proxyAdminPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "proxyBootstrapTemplatePath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "serviceCluster" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "statNameLength" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "statsdUdpAddress" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "zipkinAddress" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "availabilityZone" = mkOverride 1002 null;

        "binaryPath" = mkOverride 1002 null;

        "concurrency" = mkOverride 1002 null;

        "configPath" = mkOverride 1002 null;

        "connectTimeout" = mkOverride 1002 null;

        "controlPlaneAuthPolicy" = mkOverride 1002 null;

        "customConfigFile" = mkOverride 1002 null;

        "discoveryAddress" = mkOverride 1002 null;

        "discoveryRefreshDelay" = mkOverride 1002 null;

        "drainDuration" = mkOverride 1002 null;

        "interceptionMode" = mkOverride 1002 null;

        "parentShutdownDuration" = mkOverride 1002 null;

        "proxyAdminPort" = mkOverride 1002 null;

        "proxyBootstrapTemplatePath" = mkOverride 1002 null;

        "serviceCluster" = mkOverride 1002 null;

        "statNameLength" = mkOverride 1002 null;

        "statsdUdpAddress" = mkOverride 1002 null;

        "zipkinAddress" = mkOverride 1002 null;
      };
    };

    "istio_mixer_apikey_InstanceMsg" = {
      options = {
        "api" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "apiKey" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "apiOperation" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "apiVersion" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "timestamp" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_TimeStamp"));
        };
      };

      config = {
        "api" = mkOverride 1002 null;

        "apiKey" = mkOverride 1002 null;

        "apiOperation" = mkOverride 1002 null;

        "apiVersion" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "timestamp" = mkOverride 1002 null;
      };
    };

    "istio_mixer_authorization_ActionMsg" = {
      options = {
        "method" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "namespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "path" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "properties" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "service" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "method" = mkOverride 1002 null;

        "namespace" = mkOverride 1002 null;

        "path" = mkOverride 1002 null;

        "properties" = mkOverride 1002 null;

        "service" = mkOverride 1002 null;
      };
    };

    "istio_mixer_authorization_InstanceMsg" = {
      options = {
        "action" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_authorization_ActionMsg"));
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "subject" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_authorization_SubjectMsg"));
        };
      };

      config = {
        "action" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "subject" = mkOverride 1002 null;
      };
    };

    "istio_mixer_authorization_SubjectMsg" = {
      options = {
        "groups" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "properties" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "groups" = mkOverride 1002 null;

        "properties" = mkOverride 1002 null;

        "user" = mkOverride 1002 null;
      };
    };

    "istio_mixer_checknothing_InstanceMsg" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };
    };

    "istio_mixer_edge_InstanceMsg" = {
      options = {
        "apiProtocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "contextProtocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "destinationOwner" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "destinationUid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "destinationWorkloadName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "destinationWorkloadNamespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sourceOwner" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sourceUid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sourceWorkloadName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sourceWorkloadNamespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "timestamp" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_TimeStamp"));
        };
      };

      config = {
        "apiProtocol" = mkOverride 1002 null;

        "contextProtocol" = mkOverride 1002 null;

        "destinationOwner" = mkOverride 1002 null;

        "destinationUid" = mkOverride 1002 null;

        "destinationWorkloadName" = mkOverride 1002 null;

        "destinationWorkloadNamespace" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "sourceOwner" = mkOverride 1002 null;

        "sourceUid" = mkOverride 1002 null;

        "sourceWorkloadName" = mkOverride 1002 null;

        "sourceWorkloadNamespace" = mkOverride 1002 null;

        "timestamp" = mkOverride 1002 null;
      };
    };

    "istio_mixer_listentry_InstanceMsg" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "value" = mkOverride 1002 null;
      };
    };

    "istio_mixer_logentry_InstanceMsg" = {
      options = {
        "monitoredResourceDimensions" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "monitoredResourceType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "severity" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "timestamp" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_TimeStamp"));
        };

        "variables" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "monitoredResourceDimensions" = mkOverride 1002 null;

        "monitoredResourceType" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "severity" = mkOverride 1002 null;

        "timestamp" = mkOverride 1002 null;

        "variables" = mkOverride 1002 null;
      };
    };

    "istio_mixer_metric_InstanceMsg" = {
      options = {
        "dimensions" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "monitoredResourceDimensions" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "monitoredResourceType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "value" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_Value"));
        };
      };

      config = {
        "dimensions" = mkOverride 1002 null;

        "monitoredResourceDimensions" = mkOverride 1002 null;

        "monitoredResourceType" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "value" = mkOverride 1002 null;
      };
    };

    "istio_mixer_quota_InstanceMsg" = {
      options = {
        "dimensions" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dimensions" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;
      };
    };

    "istio_mixer_reportnothing_InstanceMsg" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };
    };

    "istio_mixer_tracespan_InstanceMsg" = {
      options = {
        "clientSpan" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "endTime" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_TimeStamp"));
        };

        "httpStatusCode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "parentSpanId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "rewriteClientSpanId" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "spanId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "spanName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "spanTags" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "startTime" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_policy_v1beta1_TimeStamp"));
        };

        "traceId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "clientSpan" = mkOverride 1002 null;

        "endTime" = mkOverride 1002 null;

        "httpStatusCode" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "parentSpanId" = mkOverride 1002 null;

        "rewriteClientSpanId" = mkOverride 1002 null;

        "spanId" = mkOverride 1002 null;

        "spanName" = mkOverride 1002 null;

        "spanTags" = mkOverride 1002 null;

        "startTime" = mkOverride 1002 null;

        "traceId" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_Attributes" = {
      options = {
        "attributes" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "attributes" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_Attributes_AttributeValue" = {
      options = {
        "value" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "value" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CheckRequest" = {
      options = {
        "attributes" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_v1_CompressedAttributes"));
        };

        "deduplicationId" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "globalWordCount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "quotas" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "attributes" = mkOverride 1002 null;

        "deduplicationId" = mkOverride 1002 null;

        "globalWordCount" = mkOverride 1002 null;

        "quotas" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CheckRequest_QuotaParams" = {
      options = {
        "amount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "bestEffort" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "amount" = mkOverride 1002 null;

        "bestEffort" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CheckResponse" = {
      options = {
        "precondition" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_v1_CheckResponse_PreconditionResult"));
        };

        "quotas" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "precondition" = mkOverride 1002 null;

        "quotas" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CheckResponse_PreconditionResult" = {
      options = {
        "referencedAttributes" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_v1_ReferencedAttributes"));
        };

        "routeDirective" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_v1_RouteDirective"));
        };

        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "google_rpc_Status"));
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "validUseCount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "referencedAttributes" = mkOverride 1002 null;

        "routeDirective" = mkOverride 1002 null;

        "status" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;

        "validUseCount" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CheckResponse_QuotaResult" = {
      options = {
        "grantedAmount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "referencedAttributes" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_mixer_v1_ReferencedAttributes"));
        };

        "validDuration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "grantedAmount" = mkOverride 1002 null;

        "referencedAttributes" = mkOverride 1002 null;

        "validDuration" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_CompressedAttributes" = {
      options = {
        "bools" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.bool));
        };

        "bytes" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "doubles" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };

        "durations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };

        "int64s" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };

        "stringMaps" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "strings" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };

        "timestamps" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "words" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "bools" = mkOverride 1002 null;

        "bytes" = mkOverride 1002 null;

        "doubles" = mkOverride 1002 null;

        "durations" = mkOverride 1002 null;

        "int64s" = mkOverride 1002 null;

        "stringMaps" = mkOverride 1002 null;

        "strings" = mkOverride 1002 null;

        "timestamps" = mkOverride 1002 null;

        "words" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_HeaderOperation" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "operation" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "operation" = mkOverride 1002 null;

        "value" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_ReferencedAttributes" = {
      options = {
        "attributeMatches" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_mixer_v1_ReferencedAttributes_AttributeMatch")));
        };

        "words" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "attributeMatches" = mkOverride 1002 null;

        "words" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_ReferencedAttributes_AttributeMatch" = {
      options = {
        "condition" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "mapKey" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "regex" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "condition" = mkOverride 1002 null;

        "mapKey" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "regex" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_ReportRequest" = {
      options = {
        "attributes" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_mixer_v1_CompressedAttributes")));
        };

        "defaultWords" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "globalWordCount" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "attributes" = mkOverride 1002 null;

        "defaultWords" = mkOverride 1002 null;

        "globalWordCount" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_ReportResponse" = { };

    "istio_mixer_v1_RouteDirective" = {
      options = {
        "directResponseBody" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "directResponseCode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "requestHeaderOperations" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_mixer_v1_HeaderOperation")));
        };

        "responseHeaderOperations" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_mixer_v1_HeaderOperation")));
        };
      };

      config = {
        "directResponseBody" = mkOverride 1002 null;

        "directResponseCode" = mkOverride 1002 null;

        "requestHeaderOperations" = mkOverride 1002 null;

        "responseHeaderOperations" = mkOverride 1002 null;
      };
    };

    "istio_mixer_v1_StringMap" = {
      options = {
        "entries" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };
      };

      config = {
        "entries" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_ConnectionPoolSettings" = {
      options = {
        "http" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_ConnectionPoolSettings_HTTPSettings"));
        };

        "tcp" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_ConnectionPoolSettings_TCPSettings"));
        };
      };

      config = {
        "http" = mkOverride 1002 null;

        "tcp" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_ConnectionPoolSettings_HTTPSettings" = {
      options = {
        "http1MaxPendingRequests" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "http2MaxRequests" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "maxRequestsPerConnection" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "maxRetries" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "http1MaxPendingRequests" = mkOverride 1002 null;

        "http2MaxRequests" = mkOverride 1002 null;

        "maxRequestsPerConnection" = mkOverride 1002 null;

        "maxRetries" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_ConnectionPoolSettings_TCPSettings" = {
      options = {
        "connectTimeout" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };

        "maxConnections" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "connectTimeout" = mkOverride 1002 null;

        "maxConnections" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_CorsPolicy" = {
      options = {
        "allowCredentials" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_BoolValue"));
        };

        "allowHeaders" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "allowMethods" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "allowOrigin" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "exposeHeaders" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "maxAge" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };
      };

      config = {
        "allowCredentials" = mkOverride 1002 null;

        "allowHeaders" = mkOverride 1002 null;

        "allowMethods" = mkOverride 1002 null;

        "allowOrigin" = mkOverride 1002 null;

        "exposeHeaders" = mkOverride 1002 null;

        "maxAge" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Destination" = {
      options = {
        "host" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_PortSelector"));
        };

        "subset" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "host" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "subset" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_DestinationRule" = {
      options = {
        "host" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "subsets" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Subset")));
        };

        "trafficPolicy" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_TrafficPolicy"));
        };
      };

      config = {
        "host" = mkOverride 1002 null;

        "subsets" = mkOverride 1002 null;

        "trafficPolicy" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_DestinationWeight" = {
      options = {
        "destination" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Destination"));
        };

        "weight" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "destination" = mkOverride 1002 null;

        "weight" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_EnvoyFilter" = {
      options = {
        "filters" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_EnvoyFilter_Filter")));
        };

        "workloadLabels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "filters" = mkOverride 1002 null;

        "workloadLabels" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_EnvoyFilter_Filter" = {
      options = {
        "filterConfig" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Struct"));
        };

        "filterName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "filterType" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "insertPosition" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_EnvoyFilter_InsertPosition"));
        };

        "listenerMatch" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_EnvoyFilter_ListenerMatch"));
        };
      };

      config = {
        "filterConfig" = mkOverride 1002 null;

        "filterName" = mkOverride 1002 null;

        "filterType" = mkOverride 1002 null;

        "insertPosition" = mkOverride 1002 null;

        "listenerMatch" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_EnvoyFilter_InsertPosition" = {
      options = {
        "index" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "relativeTo" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "index" = mkOverride 1002 null;

        "relativeTo" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_EnvoyFilter_ListenerMatch" = {
      options = {
        "address" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "listenerProtocol" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "listenerType" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "portNamePrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "portNumber" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "address" = mkOverride 1002 null;

        "listenerProtocol" = mkOverride 1002 null;

        "listenerType" = mkOverride 1002 null;

        "portNamePrefix" = mkOverride 1002 null;

        "portNumber" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Gateway" = {
      options = {
        "selector" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "servers" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Server")));
        };
      };

      config = {
        "selector" = mkOverride 1002 null;

        "servers" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection" = {
      options = {
        "abort" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPFaultInjection_Abort"));
        };

        "delay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPFaultInjection_Delay"));
        };
      };

      config = {
        "abort" = mkOverride 1002 null;

        "delay" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Abort" = {
      options = {
        "errorType" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "percent" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "errorType" = mkOverride 1002 null;

        "percent" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Abort_GrpcStatus" = {
      options = {
        "grpcStatus" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "grpcStatus" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Abort_Http2Error" = {
      options = {
        "http2Error" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "http2Error" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Abort_HttpStatus" = {
      options = {
        "httpStatus" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "httpStatus" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Delay" = {
      options = {
        "httpDelayType" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "percent" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "httpDelayType" = mkOverride 1002 null;

        "percent" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Delay_ExponentialDelay" = {
      options = {
        "exponentialDelay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };
      };

      config = {
        "exponentialDelay" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPFaultInjection_Delay_FixedDelay" = {
      options = {
        "fixedDelay" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };
      };

      config = {
        "fixedDelay" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPMatchRequest" = {
      options = {
        "authority" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_StringMatch"));
        };

        "gateways" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "headers" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };

        "method" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_StringMatch"));
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "scheme" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_StringMatch"));
        };

        "sourceLabels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "uri" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_StringMatch"));
        };
      };

      config = {
        "authority" = mkOverride 1002 null;

        "gateways" = mkOverride 1002 null;

        "headers" = mkOverride 1002 null;

        "method" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "scheme" = mkOverride 1002 null;

        "sourceLabels" = mkOverride 1002 null;

        "uri" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPRedirect" = {
      options = {
        "authority" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "uri" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "authority" = mkOverride 1002 null;

        "uri" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPRetry" = {
      options = {
        "attempts" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "perTryTimeout" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };
      };

      config = {
        "attempts" = mkOverride 1002 null;

        "perTryTimeout" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPRewrite" = {
      options = {
        "authority" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "uri" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "authority" = mkOverride 1002 null;

        "uri" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_HTTPRoute" = {
      options = {
        "appendHeaders" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "corsPolicy" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_CorsPolicy"));
        };

        "fault" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPFaultInjection"));
        };

        "match" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_HTTPMatchRequest")));
        };

        "mirror" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Destination"));
        };

        "redirect" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPRedirect"));
        };

        "removeResponseHeaders" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "retries" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPRetry"));
        };

        "rewrite" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_HTTPRewrite"));
        };

        "route" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_DestinationWeight")));
        };

        "timeout" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };

        "websocketUpgrade" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "appendHeaders" = mkOverride 1002 null;

        "corsPolicy" = mkOverride 1002 null;

        "fault" = mkOverride 1002 null;

        "match" = mkOverride 1002 null;

        "mirror" = mkOverride 1002 null;

        "redirect" = mkOverride 1002 null;

        "removeResponseHeaders" = mkOverride 1002 null;

        "retries" = mkOverride 1002 null;

        "rewrite" = mkOverride 1002 null;

        "route" = mkOverride 1002 null;

        "timeout" = mkOverride 1002 null;

        "websocketUpgrade" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_L4MatchAttributes" = {
      options = {
        "destinationSubnets" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "gateways" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "sourceLabels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "sourceSubnet" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "destinationSubnets" = mkOverride 1002 null;

        "gateways" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "sourceLabels" = mkOverride 1002 null;

        "sourceSubnet" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings" = {
      options = {
        "lbPolicy" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "lbPolicy" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHash" = {
      options = {
        "consistentHash" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB"));
        };
      };

      config = {
        "consistentHash" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB" = {
      options = {
        "hashKey" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "minimumRingSize" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "hashKey" = mkOverride 1002 null;

        "minimumRingSize" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB_HTTPCookie" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "path" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "ttl" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "path" = mkOverride 1002 null;

        "ttl" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB_HttpCookie" = {
      options = {
        "httpCookie" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB_HTTPCookie"));
        };
      };

      config = {
        "httpCookie" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB_HttpHeaderName" = {
      options = {
        "httpHeaderName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "httpHeaderName" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_ConsistentHashLB_UseSourceIp" = {
      options = {
        "useSourceIp" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "useSourceIp" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_LoadBalancerSettings_Simple" = {
      options = {
        "simple" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "simple" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_OutlierDetection" = {
      options = {
        "baseEjectionTime" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };

        "consecutiveErrors" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "interval" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Duration"));
        };

        "maxEjectionPercent" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "baseEjectionTime" = mkOverride 1002 null;

        "consecutiveErrors" = mkOverride 1002 null;

        "interval" = mkOverride 1002 null;

        "maxEjectionPercent" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Port" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "number" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "protocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;

        "number" = mkOverride 1002 null;

        "protocol" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_PortSelector" = {
      options = {
        "port" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "port" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_PortSelector_Name" = {
      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_PortSelector_Number" = {
      options = {
        "number" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "number" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Server" = {
      options = {
        "hosts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Port"));
        };

        "tls" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_Server_TLSOptions"));
        };
      };

      config = {
        "hosts" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "tls" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Server_TLSOptions" = {
      options = {
        "caCertificates" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "httpsRedirect" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };

        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "privateKey" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "serverCertificate" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "subjectAltNames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "caCertificates" = mkOverride 1002 null;

        "httpsRedirect" = mkOverride 1002 null;

        "mode" = mkOverride 1002 null;

        "privateKey" = mkOverride 1002 null;

        "serverCertificate" = mkOverride 1002 null;

        "subjectAltNames" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_ServiceEntry" = {
      options = {
        "addresses" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "endpoints" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_ServiceEntry_Endpoint")));
        };

        "hosts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "location" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "ports" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_Port")));
        };

        "resolution" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "addresses" = mkOverride 1002 null;

        "endpoints" = mkOverride 1002 null;

        "hosts" = mkOverride 1002 null;

        "location" = mkOverride 1002 null;

        "ports" = mkOverride 1002 null;

        "resolution" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_ServiceEntry_Endpoint" = {
      options = {
        "address" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "ports" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.int));
        };
      };

      config = {
        "address" = mkOverride 1002 null;

        "labels" = mkOverride 1002 null;

        "ports" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_StringMatch" = {
      options = {
        "matchType" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "matchType" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_StringMatch_Exact" = {
      options = {
        "exact" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "exact" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_StringMatch_Prefix" = {
      options = {
        "prefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "prefix" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_StringMatch_Regex" = {
      options = {
        "regex" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "regex" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_Subset" = {
      options = {
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "trafficPolicy" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_TrafficPolicy"));
        };
      };

      config = {
        "labels" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;

        "trafficPolicy" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TCPRoute" = {
      options = {
        "match" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_L4MatchAttributes")));
        };

        "route" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_DestinationWeight")));
        };
      };

      config = {
        "match" = mkOverride 1002 null;

        "route" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TLSMatchAttributes" = {
      options = {
        "destinationSubnets" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "gateways" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "sniHosts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "sourceLabels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "sourceSubnet" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "destinationSubnets" = mkOverride 1002 null;

        "gateways" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "sniHosts" = mkOverride 1002 null;

        "sourceLabels" = mkOverride 1002 null;

        "sourceSubnet" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TLSRoute" = {
      options = {
        "match" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_TLSMatchAttributes")));
        };

        "route" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_DestinationWeight")));
        };
      };

      config = {
        "match" = mkOverride 1002 null;

        "route" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TLSSettings" = {
      options = {
        "caCertificates" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "clientCertificate" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "privateKey" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "sni" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "subjectAltNames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "caCertificates" = mkOverride 1002 null;

        "clientCertificate" = mkOverride 1002 null;

        "mode" = mkOverride 1002 null;

        "privateKey" = mkOverride 1002 null;

        "sni" = mkOverride 1002 null;

        "subjectAltNames" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TrafficPolicy" = {
      options = {
        "connectionPool" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_ConnectionPoolSettings"));
        };

        "loadBalancer" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_LoadBalancerSettings"));
        };

        "outlierDetection" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_OutlierDetection"));
        };

        "portLevelSettings" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_TrafficPolicy_PortTrafficPolicy")));
        };

        "tls" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_TLSSettings"));
        };
      };

      config = {
        "connectionPool" = mkOverride 1002 null;

        "loadBalancer" = mkOverride 1002 null;

        "outlierDetection" = mkOverride 1002 null;

        "portLevelSettings" = mkOverride 1002 null;

        "tls" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_TrafficPolicy_PortTrafficPolicy" = {
      options = {
        "connectionPool" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_ConnectionPoolSettings"));
        };

        "loadBalancer" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_LoadBalancerSettings"));
        };

        "outlierDetection" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_OutlierDetection"));
        };

        "port" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_PortSelector"));
        };

        "tls" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_networking_v1alpha3_TLSSettings"));
        };
      };

      config = {
        "connectionPool" = mkOverride 1002 null;

        "loadBalancer" = mkOverride 1002 null;

        "outlierDetection" = mkOverride 1002 null;

        "port" = mkOverride 1002 null;

        "tls" = mkOverride 1002 null;
      };
    };

    "istio_networking_v1alpha3_VirtualService" = {
      options = {
        "gateways" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "hosts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "http" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_HTTPRoute")));
        };

        "tcp" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_TCPRoute")));
        };

        "tls" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_networking_v1alpha3_TLSRoute")));
        };
      };

      config = {
        "gateways" = mkOverride 1002 null;

        "hosts" = mkOverride 1002 null;

        "http" = mkOverride 1002 null;

        "tcp" = mkOverride 1002 null;

        "tls" = mkOverride 1002 null;
      };
    };

    "istio_policy_v1beta1_Action" = {
      options = {
        "handler" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "instances" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "handler" = mkOverride 1002 null;

        "instances" = mkOverride 1002 null;
      };
    };

    "istio_policy_v1beta1_Rule" = {
      options = {
        "actions" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_policy_v1beta1_Action")));
        };

        "match" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "actions" = mkOverride 1002 null;

        "match" = mkOverride 1002 null;
      };
    };

    "istio_policy_v1beta1_TimeStamp" = {
      options = {
        "value" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "protobuf_types_Timestamp"));
        };
      };

      config = {
        "value" = mkOverride 1002 null;
      };
    };

    "istio_policy_v1beta1_Value" = {
      options = {
        "value" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "value" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_AccessRule" = {
      options = {
        "constraints" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_rbac_v1alpha1_AccessRule_Constraint")));
        };

        "methods" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "paths" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "services" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "constraints" = mkOverride 1002 null;

        "methods" = mkOverride 1002 null;

        "paths" = mkOverride 1002 null;

        "services" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_AccessRule_Constraint" = {
      options = {
        "key" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "values" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "key" = mkOverride 1002 null;

        "values" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_RbacConfig" = {
      options = {
        "exclusion" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_rbac_v1alpha1_RbacConfig_Target"));
        };

        "inclusion" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_rbac_v1alpha1_RbacConfig_Target"));
        };

        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "exclusion" = mkOverride 1002 null;

        "inclusion" = mkOverride 1002 null;

        "mode" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_RbacConfig_Target" = {
      options = {
        "namespaces" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };

        "services" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "namespaces" = mkOverride 1002 null;

        "services" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_RoleRef" = {
      options = {
        "kind" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "kind" = mkOverride 1002 null;

        "name" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_ServiceRole" = {
      options = {
        "rules" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_rbac_v1alpha1_AccessRule")));
        };
      };

      config = {
        "rules" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_ServiceRoleBinding" = {
      options = {
        "mode" = mkOption {
          description = "";
          type = types.unspecified;
        };

        "roleRef" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "istio_rbac_v1alpha1_RoleRef"));
        };

        "subjects" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "istio_rbac_v1alpha1_Subject")));
        };
      };

      config = {
        "mode" = mkOverride 1002 null;

        "roleRef" = mkOverride 1002 null;

        "subjects" = mkOverride 1002 null;
      };
    };

    "istio_rbac_v1alpha1_Subject" = {
      options = {
        "group" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "properties" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };

        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "group" = mkOverride 1002 null;

        "properties" = mkOverride 1002 null;

        "user" = mkOverride 1002 null;
      };
    };

    "protobuf_duration_Duration" = {
      options = {
        "nanos" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "seconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "nanos" = mkOverride 1002 null;

        "seconds" = mkOverride 1002 null;
      };
    };

    "protobuf_types_Any" = {
      options = {
        "typeUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };

        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "typeUrl" = mkOverride 1002 null;

        "value" = mkOverride 1002 null;
      };
    };

    "protobuf_types_BoolValue" = {
      options = {
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "value" = mkOverride 1002 null;
      };
    };

    "protobuf_types_Duration" = {
      options = {
        "nanos" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "seconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "nanos" = mkOverride 1002 null;

        "seconds" = mkOverride 1002 null;
      };
    };

    "protobuf_types_Struct" = {
      options = {
        "fields" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
      };

      config = {
        "fields" = mkOverride 1002 null;
      };
    };

    "protobuf_types_Timestamp" = {
      options = {
        "nanos" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };

        "seconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "nanos" = mkOverride 1002 null;

        "seconds" = mkOverride 1002 null;
      };
    };

    "protobuf_types_Value" = {
      options = {
        "kind" = mkOption {
          description = "";
          type = types.unspecified;
        };
      };

      config = {
        "kind" = mkOverride 1002 null;
      };
    };

  } // (import ./istio-overrides.nix { inherit definitions lib; });
in
{
  kubernetes.customResources = [
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "DestinationRule";
      description = "";
      module = definitions."istio_networking_v1alpha3_DestinationRule";
    }
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "EnvoyFilter";
      description = "";
      module = definitions."istio_networking_v1alpha3_EnvoyFilter";
    }
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "Gateway";
      description = "";
      module = definitions."istio_networking_v1alpha3_Gateway";
    }
    {
      group = "authentication.istio.io";
      version = "v1alpha1";
      kind = "Policy";
      description = "";
      module = definitions."istio_authentication_v1alpha1_Policy";
    }
    {
      group = "rbac.istio.io";
      version = "v1alpha1";
      kind = "RbacConfig";
      description = "";
      module = definitions."istio_rbac_v1alpha1_RbacConfig";
    }
    {
      group = "policy.istio.io";
      version = "v1beta1";
      kind = "Rule";
      description = "";
      module = definitions."istio_policy_v1beta1_Rule";
    }
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "ServiceEntry";
      description = "";
      module = definitions."istio_networking_v1alpha3_ServiceEntry";
    }
    {
      group = "rbac.istio.io";
      version = "v1alpha1";
      kind = "ServiceRole";
      description = "";
      module = definitions."istio_rbac_v1alpha1_ServiceRole";
    }
    {
      group = "rbac.istio.io";
      version = "v1alpha1";
      kind = "ServiceRoleBinding";
      description = "";
      module = definitions."istio_rbac_v1alpha1_ServiceRoleBinding";
    }
    {
      group = "networking.istio.io";
      version = "v1alpha3";
      kind = "VirtualService";
      description = "";
      module = definitions."istio_networking_v1alpha3_VirtualService";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "apikey";
      description = "";
      module = definitions."istio_mixer_apikey_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "authorization";
      description = "";
      module = definitions."istio_mixer_authorization_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "bypass";
      description = "";
      module = definitions."istio_adapter_bypass_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "checknothing";
      description = "";
      module = definitions."istio_mixer_checknothing_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "circonus";
      description = "";
      module = definitions."istio_adapter_circonus_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "denier";
      description = "";
      module = definitions."istio_adapter_denier_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "edge";
      description = "";
      module = definitions."istio_mixer_edge_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "fluentd";
      description = "";
      module = definitions."istio_adapter_fluentd_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "kubernetesenv";
      description = "";
      module = definitions."istio_adapter_kubernetesenv_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "listentry";
      description = "";
      module = definitions."istio_mixer_listentry_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "logentry";
      description = "";
      module = definitions."istio_mixer_logentry_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "memquota";
      description = "";
      module = definitions."istio_adapter_memquota_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "metric";
      description = "";
      module = definitions."istio_mixer_metric_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "opa";
      description = "";
      module = definitions."istio_adapter_opa_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "prometheus";
      description = "";
      module = definitions."istio_adapter_prometheus_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "quota";
      description = "";
      module = definitions."istio_mixer_quota_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "rbac";
      description = "";
      module = definitions."istio_adapter_rbac_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "redisquota";
      description = "";
      module = definitions."istio_adapter_redisquota_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "reportnothing";
      description = "";
      module = definitions."istio_mixer_reportnothing_InstanceMsg";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "servicecontrol";
      description = "";
      module = definitions."istio_adapter_servicecontrol_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "signalfx";
      description = "";
      module = definitions."istio_adapter_signalfx_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "solarwinds";
      description = "";
      module = definitions."istio_adapter_solarwinds_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "stackdriver";
      description = "";
      module = definitions."istio_adapter_stackdriver_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "statsd";
      description = "";
      module = definitions."istio_adapter_statsd_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "stdio";
      description = "";
      module = definitions."istio_adapter_stdio_Params";
    }
    {
      group = "config.istio.io";
      version = "v1alpha2";
      kind = "tracespan";
      description = "";
      module = definitions."istio_mixer_tracespan_InstanceMsg";
    }
  ];
}
