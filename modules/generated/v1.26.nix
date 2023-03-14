# This file was generated with kubenix k8s generator, do not edit
{ lib, options, config, ... }:

with lib;

let
  hasAttrNotNull = attr: set: hasAttr attr set && !isNull set.${attr};

  attrsToList = values:
    if values != null
    then
      sort
        (a: b:
          if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b)
          then a._priority < b._priority
          else false
        )
        (mapAttrsToList (n: v: v) values)
    else
      values;

  getDefaults = resource: group: version: kind:
    catAttrs "default" (filter
      (default:
        (default.resource == null || default.resource == resource) &&
        (default.group == null || default.group == group) &&
        (default.version == null || default.version == version) &&
        (default.kind == null || default.kind == kind)
      )
      config.defaults);

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

  # todo: can we use mkOrder
  mergeValuesByKey = mergeKey: values:
    listToAttrs (imap0
      (i: value: nameValuePair
        (
          if isAttrs value.${mergeKey}
          then toString value.${mergeKey}.content
          else (toString value.${mergeKey})
        )
        (value // { _priority = i; }))
      values);

  submoduleOf = ref: types.submodule ({ name, ... }: {
    options = definitions."${ref}".options or { };
    config = definitions."${ref}".config or { };
  });

  submoduleWithMergeOf = ref: mergeKey: types.submodule ({ name, ... }:
    let
      convertName = name:
        if definitions."${ref}".options.${mergeKey}.type == types.int
        then toInt name
        else name;
    in
    {
      options = definitions."${ref}".options // {
        # position in original array
        _priority = mkOption { type = types.nullOr types.int; default = null; };
      };
      config = definitions."${ref}".config // {
        ${mergeKey} = mkOverride 1002 (convertName name);
      };
    });

  submoduleForDefinition = ref: resource: kind: group: version:
    let
      apiVersion = if group == "core" then version else "${group}/${version}";
    in
    types.submodule ({ name, ... }: {
      imports = getDefaults resource group version kind;
      options = definitions."${ref}".options;
      config = mkMerge [
        definitions."${ref}".config
        {
          kind = mkOptionDefault kind;
          apiVersion = mkOptionDefault apiVersion;

          # metdata.name cannot use option default, due deep config
          metadata.name = mkOptionDefault name;
        }
      ];
    });

  coerceAttrsOfSubmodulesToListByKey = ref: mergeKey: (types.coercedTo
    (types.listOf (submoduleOf ref))
    (mergeValuesByKey mergeKey)
    (types.attrsOf (submoduleWithMergeOf ref mergeKey))
  );

  definitions = {
    "io.k8s.api.admissionregistration.v1.MutatingWebhook" = {

      options = {
        "admissionReviewVersions" = mkOption {
          description = "AdmissionReviewVersions is an ordered list of preferred `AdmissionReview` versions the Webhook expects. API server will try to use first version in the list which it supports. If none of the versions specified in this list supported by API server, validation will fail for this object. If a persisted webhook configuration specifies allowed versions and does not include any versions known to the API Server, calls to the webhook will fail and be subject to the failure policy.";
          type = (types.listOf types.str);
        };
        "clientConfig" = mkOption {
          description = "ClientConfig defines how to communicate with the hook. Required";
          type = (submoduleOf "io.k8s.api.admissionregistration.v1.WebhookClientConfig");
        };
        "failurePolicy" = mkOption {
          description = "FailurePolicy defines how unrecognized errors from the admission endpoint are handled - allowed values are Ignore or Fail. Defaults to Fail.";
          type = (types.nullOr types.str);
        };
        "matchPolicy" = mkOption {
          description = "matchPolicy defines how the \"rules\" list is used to match incoming requests. Allowed values are \"Exact\" or \"Equivalent\".\n\n- Exact: match a request only if it exactly matches a specified rule. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, but \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would not be sent to the webhook.\n\n- Equivalent: match a request if modifies a resource listed in rules, even via another API group or version. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, and \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would be converted to apps/v1 and sent to the webhook.\n\nDefaults to \"Equivalent\"";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the admission webhook. Name should be fully qualified, e.g., imagepolicy.kubernetes.io, where \"imagepolicy\" is the name of the webhook, and kubernetes.io is the name of the organization. Required.";
          type = types.str;
        };
        "namespaceSelector" = mkOption {
          description = "NamespaceSelector decides whether to run the webhook on an object based on whether the namespace for that object matches the selector. If the object itself is a namespace, the matching is performed on object.metadata.labels. If the object is another cluster scoped resource, it never skips the webhook.\n\nFor example, to run the webhook on any objects whose namespace is not associated with \"runlevel\" of \"0\" or \"1\";  you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"runlevel\",\n      \"operator\": \"NotIn\",\n      \"values\": [\n        \"0\",\n        \"1\"\n      ]\n    }\n  ]\n}\n\nIf instead you want to only run the webhook on any objects whose namespace is associated with the \"environment\" of \"prod\" or \"staging\"; you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"environment\",\n      \"operator\": \"In\",\n      \"values\": [\n        \"prod\",\n        \"staging\"\n      ]\n    }\n  ]\n}\n\nSee https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ for more examples of label selectors.\n\nDefault to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "objectSelector" = mkOption {
          description = "ObjectSelector decides whether to run the webhook based on if the object has matching labels. objectSelector is evaluated against both the oldObject and newObject that would be sent to the webhook, and is considered to match if either object matches the selector. A null object (oldObject in the case of create, or newObject in the case of delete) or an object that cannot have labels (like a DeploymentRollback or a PodProxyOptions object) is not considered to match. Use the object selector only if the webhook is opt-in, because end users may skip the admission webhook by setting the labels. Default to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "reinvocationPolicy" = mkOption {
          description = "reinvocationPolicy indicates whether this webhook should be called multiple times as part of a single admission evaluation. Allowed values are \"Never\" and \"IfNeeded\".\n\nNever: the webhook will not be called more than once in a single admission evaluation.\n\nIfNeeded: the webhook will be called at least one additional time as part of the admission evaluation if the object being admitted is modified by other admission plugins after the initial webhook call. Webhooks that specify this option *must* be idempotent, able to process objects they previously admitted. Note: * the number of additional invocations is not guaranteed to be exactly one. * if additional invocations result in further modifications to the object, webhooks are not guaranteed to be invoked again. * webhooks that use this option may be reordered to minimize the number of additional invocations. * to validate an object after all mutations are guaranteed complete, use a validating admission webhook instead.\n\nDefaults to \"Never\".";
          type = (types.nullOr types.str);
        };
        "rules" = mkOption {
          description = "Rules describes what operations on what resources/subresources the webhook cares about. The webhook cares about an operation if it matches _any_ Rule. However, in order to prevent ValidatingAdmissionWebhooks and MutatingAdmissionWebhooks from putting the cluster in a state which cannot be recovered from without completely disabling the plugin, ValidatingAdmissionWebhooks and MutatingAdmissionWebhooks are never called on admission requests for ValidatingWebhookConfiguration and MutatingWebhookConfiguration objects.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1.RuleWithOperations")));
        };
        "sideEffects" = mkOption {
          description = "SideEffects states whether this webhook has side effects. Acceptable values are: None, NoneOnDryRun (webhooks created via v1beta1 may also specify Some or Unknown). Webhooks with side effects MUST implement a reconciliation system, since a request may be rejected by a future step in the admission chain and the side effects therefore need to be undone. Requests with the dryRun attribute will be auto-rejected if they match a webhook with sideEffects == Unknown or Some.";
          type = types.str;
        };
        "timeoutSeconds" = mkOption {
          description = "TimeoutSeconds specifies the timeout for this webhook. After the timeout passes, the webhook call will be ignored or the API call will fail based on the failure policy. The timeout value must be between 1 and 30 seconds. Default to 10 seconds.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "failurePolicy" = mkOverride 1002 null;
        "matchPolicy" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "objectSelector" = mkOverride 1002 null;
        "reinvocationPolicy" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.MutatingWebhookConfiguration" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "webhooks" = mkOption {
          description = "Webhooks is a list of webhooks and the affected resources and operations.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.admissionregistration.v1.MutatingWebhook" "name"));
          apply = attrsToList;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "webhooks" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.MutatingWebhookConfigurationList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of MutatingWebhookConfiguration.";
          type = (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1.MutatingWebhookConfiguration"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.RuleWithOperations" = {

      options = {
        "apiGroups" = mkOption {
          description = "APIGroups is the API groups the resources belong to. '*' is all groups. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "apiVersions" = mkOption {
          description = "APIVersions is the API versions the resources belong to. '*' is all versions. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "operations" = mkOption {
          description = "Operations is the operations the admission hook cares about - CREATE, UPDATE, DELETE, CONNECT or * for all of those operations and any future admission operations that are added. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "Resources is a list of resources this rule applies to.\n\nFor example: 'pods' means pods. 'pods/log' means the log subresource of pods. '*' means all resources, but not subresources. 'pods/*' means all subresources of pods. '*/scale' means all scale subresources. '*/*' means all resources and their subresources.\n\nIf wildcard is present, the validation rule will ensure resources do not overlap with each other.\n\nDepending on the enclosing object, subresources might not be allowed. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "scope" = mkOption {
          description = "scope specifies the scope of this rule. Valid values are \"Cluster\", \"Namespaced\", and \"*\" \"Cluster\" means that only cluster-scoped resources will match this rule. Namespace API objects are cluster-scoped. \"Namespaced\" means that only namespaced resources will match this rule. \"*\" means that there are no scope restrictions. Subresources match the scope of their parent resource. Default is \"*\".";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroups" = mkOverride 1002 null;
        "apiVersions" = mkOverride 1002 null;
        "operations" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "scope" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.ServiceReference" = {

      options = {
        "name" = mkOption {
          description = "`name` is the name of the service. Required";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "`namespace` is the namespace of the service. Required";
          type = types.str;
        };
        "path" = mkOption {
          description = "`path` is an optional URL path which will be sent in any request to this service.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "If specified, the port on the service that hosting webhook. Default to 443 for backward compatibility. `port` should be a valid port number (1-65535, inclusive).";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.ValidatingWebhook" = {

      options = {
        "admissionReviewVersions" = mkOption {
          description = "AdmissionReviewVersions is an ordered list of preferred `AdmissionReview` versions the Webhook expects. API server will try to use first version in the list which it supports. If none of the versions specified in this list supported by API server, validation will fail for this object. If a persisted webhook configuration specifies allowed versions and does not include any versions known to the API Server, calls to the webhook will fail and be subject to the failure policy.";
          type = (types.listOf types.str);
        };
        "clientConfig" = mkOption {
          description = "ClientConfig defines how to communicate with the hook. Required";
          type = (submoduleOf "io.k8s.api.admissionregistration.v1.WebhookClientConfig");
        };
        "failurePolicy" = mkOption {
          description = "FailurePolicy defines how unrecognized errors from the admission endpoint are handled - allowed values are Ignore or Fail. Defaults to Fail.";
          type = (types.nullOr types.str);
        };
        "matchPolicy" = mkOption {
          description = "matchPolicy defines how the \"rules\" list is used to match incoming requests. Allowed values are \"Exact\" or \"Equivalent\".\n\n- Exact: match a request only if it exactly matches a specified rule. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, but \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would not be sent to the webhook.\n\n- Equivalent: match a request if modifies a resource listed in rules, even via another API group or version. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, and \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would be converted to apps/v1 and sent to the webhook.\n\nDefaults to \"Equivalent\"";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of the admission webhook. Name should be fully qualified, e.g., imagepolicy.kubernetes.io, where \"imagepolicy\" is the name of the webhook, and kubernetes.io is the name of the organization. Required.";
          type = types.str;
        };
        "namespaceSelector" = mkOption {
          description = "NamespaceSelector decides whether to run the webhook on an object based on whether the namespace for that object matches the selector. If the object itself is a namespace, the matching is performed on object.metadata.labels. If the object is another cluster scoped resource, it never skips the webhook.\n\nFor example, to run the webhook on any objects whose namespace is not associated with \"runlevel\" of \"0\" or \"1\";  you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"runlevel\",\n      \"operator\": \"NotIn\",\n      \"values\": [\n        \"0\",\n        \"1\"\n      ]\n    }\n  ]\n}\n\nIf instead you want to only run the webhook on any objects whose namespace is associated with the \"environment\" of \"prod\" or \"staging\"; you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"environment\",\n      \"operator\": \"In\",\n      \"values\": [\n        \"prod\",\n        \"staging\"\n      ]\n    }\n  ]\n}\n\nSee https://kubernetes.io/docs/concepts/overview/working-with-objects/labels for more examples of label selectors.\n\nDefault to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "objectSelector" = mkOption {
          description = "ObjectSelector decides whether to run the webhook based on if the object has matching labels. objectSelector is evaluated against both the oldObject and newObject that would be sent to the webhook, and is considered to match if either object matches the selector. A null object (oldObject in the case of create, or newObject in the case of delete) or an object that cannot have labels (like a DeploymentRollback or a PodProxyOptions object) is not considered to match. Use the object selector only if the webhook is opt-in, because end users may skip the admission webhook by setting the labels. Default to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "rules" = mkOption {
          description = "Rules describes what operations on what resources/subresources the webhook cares about. The webhook cares about an operation if it matches _any_ Rule. However, in order to prevent ValidatingAdmissionWebhooks and MutatingAdmissionWebhooks from putting the cluster in a state which cannot be recovered from without completely disabling the plugin, ValidatingAdmissionWebhooks and MutatingAdmissionWebhooks are never called on admission requests for ValidatingWebhookConfiguration and MutatingWebhookConfiguration objects.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1.RuleWithOperations")));
        };
        "sideEffects" = mkOption {
          description = "SideEffects states whether this webhook has side effects. Acceptable values are: None, NoneOnDryRun (webhooks created via v1beta1 may also specify Some or Unknown). Webhooks with side effects MUST implement a reconciliation system, since a request may be rejected by a future step in the admission chain and the side effects therefore need to be undone. Requests with the dryRun attribute will be auto-rejected if they match a webhook with sideEffects == Unknown or Some.";
          type = types.str;
        };
        "timeoutSeconds" = mkOption {
          description = "TimeoutSeconds specifies the timeout for this webhook. After the timeout passes, the webhook call will be ignored or the API call will fail based on the failure policy. The timeout value must be between 1 and 30 seconds. Default to 10 seconds.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "failurePolicy" = mkOverride 1002 null;
        "matchPolicy" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "objectSelector" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.ValidatingWebhookConfiguration" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "webhooks" = mkOption {
          description = "Webhooks is a list of webhooks and the affected resources and operations.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.admissionregistration.v1.ValidatingWebhook" "name"));
          apply = attrsToList;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "webhooks" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.ValidatingWebhookConfigurationList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of ValidatingWebhookConfiguration.";
          type = (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1.ValidatingWebhookConfiguration"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1.WebhookClientConfig" = {

      options = {
        "caBundle" = mkOption {
          description = "`caBundle` is a PEM encoded CA bundle which will be used to validate the webhook's server certificate. If unspecified, system trust roots on the apiserver are used.";
          type = (types.nullOr types.str);
        };
        "service" = mkOption {
          description = "`service` is a reference to the service for this webhook. Either `service` or `url` must be specified.\n\nIf the webhook is running within the cluster, then you should use `service`.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1.ServiceReference"));
        };
        "url" = mkOption {
          description = "`url` gives the location of the webhook, in standard URL form (`scheme://host:port/path`). Exactly one of `url` or `service` must be specified.\n\nThe `host` should not refer to a service running in the cluster; use the `service` field instead. The host might be resolved via external DNS in some apiservers (e.g., `kube-apiserver` cannot resolve in-cluster DNS as that would be a layering violation). `host` may also be an IP address.\n\nPlease note that using `localhost` or `127.0.0.1` as a `host` is risky unless you take great care to run this webhook on all hosts which run an apiserver which might need to make calls to this webhook. Such installs are likely to be non-portable, i.e., not easy to turn up in a new cluster.\n\nThe scheme must be \"https\"; the URL must begin with \"https://\".\n\nA path is optional, and if present may be any string permissible in a URL. You may use the path to pass an arbitrary string to the webhook, for example, a cluster identifier.\n\nAttempting to use a user or basic auth e.g. \"user:password@\" is not allowed. Fragments (\"#...\") and query parameters (\"?...\") are not allowed, either.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "caBundle" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.MatchResources" = {

      options = {
        "excludeResourceRules" = mkOption {
          description = "ExcludeResourceRules describes what operations on what resources/subresources the ValidatingAdmissionPolicy should not care about. The exclude rules take precedence over include rules (if a resource matches both, it is excluded)";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.NamedRuleWithOperations")));
        };
        "matchPolicy" = mkOption {
          description = "matchPolicy defines how the \"MatchResources\" list is used to match incoming requests. Allowed values are \"Exact\" or \"Equivalent\".\n\n- Exact: match a request only if it exactly matches a specified rule. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, but \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would not be sent to the ValidatingAdmissionPolicy.\n\n- Equivalent: match a request if modifies a resource listed in rules, even via another API group or version. For example, if deployments can be modified via apps/v1, apps/v1beta1, and extensions/v1beta1, and \"rules\" only included `apiGroups:[\"apps\"], apiVersions:[\"v1\"], resources: [\"deployments\"]`, a request to apps/v1beta1 or extensions/v1beta1 would be converted to apps/v1 and sent to the ValidatingAdmissionPolicy.\n\nDefaults to \"Equivalent\"";
          type = (types.nullOr types.str);
        };
        "namespaceSelector" = mkOption {
          description = "NamespaceSelector decides whether to run the admission control policy on an object based on whether the namespace for that object matches the selector. If the object itself is a namespace, the matching is performed on object.metadata.labels. If the object is another cluster scoped resource, it never skips the policy.\n\nFor example, to run the webhook on any objects whose namespace is not associated with \"runlevel\" of \"0\" or \"1\";  you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"runlevel\",\n      \"operator\": \"NotIn\",\n      \"values\": [\n        \"0\",\n        \"1\"\n      ]\n    }\n  ]\n}\n\nIf instead you want to only run the policy on any objects whose namespace is associated with the \"environment\" of \"prod\" or \"staging\"; you will set the selector as follows: \"namespaceSelector\": {\n  \"matchExpressions\": [\n    {\n      \"key\": \"environment\",\n      \"operator\": \"In\",\n      \"values\": [\n        \"prod\",\n        \"staging\"\n      ]\n    }\n  ]\n}\n\nSee https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ for more examples of label selectors.\n\nDefault to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "objectSelector" = mkOption {
          description = "ObjectSelector decides whether to run the validation based on if the object has matching labels. objectSelector is evaluated against both the oldObject and newObject that would be sent to the cel validation, and is considered to match if either object matches the selector. A null object (oldObject in the case of create, or newObject in the case of delete) or an object that cannot have labels (like a DeploymentRollback or a PodProxyOptions object) is not considered to match. Use the object selector only if the webhook is opt-in, because end users may skip the admission webhook by setting the labels. Default to the empty LabelSelector, which matches everything.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "resourceRules" = mkOption {
          description = "ResourceRules describes what operations on what resources/subresources the ValidatingAdmissionPolicy matches. The policy cares about an operation if it matches _any_ Rule.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.NamedRuleWithOperations")));
        };
      };


      config = {
        "excludeResourceRules" = mkOverride 1002 null;
        "matchPolicy" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "objectSelector" = mkOverride 1002 null;
        "resourceRules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.NamedRuleWithOperations" = {

      options = {
        "apiGroups" = mkOption {
          description = "APIGroups is the API groups the resources belong to. '*' is all groups. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "apiVersions" = mkOption {
          description = "APIVersions is the API versions the resources belong to. '*' is all versions. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "operations" = mkOption {
          description = "Operations is the operations the admission hook cares about - CREATE, UPDATE, DELETE, CONNECT or * for all of those operations and any future admission operations that are added. If '*' is present, the length of the slice must be one. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resourceNames" = mkOption {
          description = "ResourceNames is an optional white list of names that the rule applies to.  An empty set means that everything is allowed.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "Resources is a list of resources this rule applies to.\n\nFor example: 'pods' means pods. 'pods/log' means the log subresource of pods. '*' means all resources, but not subresources. 'pods/*' means all subresources of pods. '*/scale' means all scale subresources. '*/*' means all resources and their subresources.\n\nIf wildcard is present, the validation rule will ensure resources do not overlap with each other.\n\nDepending on the enclosing object, subresources might not be allowed. Required.";
          type = (types.nullOr (types.listOf types.str));
        };
        "scope" = mkOption {
          description = "scope specifies the scope of this rule. Valid values are \"Cluster\", \"Namespaced\", and \"*\" \"Cluster\" means that only cluster-scoped resources will match this rule. Namespace API objects are cluster-scoped. \"Namespaced\" means that only namespaced resources will match this rule. \"*\" means that there are no scope restrictions. Subresources match the scope of their parent resource. Default is \"*\".";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroups" = mkOverride 1002 null;
        "apiVersions" = mkOverride 1002 null;
        "operations" = mkOverride 1002 null;
        "resourceNames" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "scope" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ParamKind" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion is the API group version the resources belong to. In format of \"group/version\". Required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the API kind the resources belong to. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ParamRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the resource being referenced.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace of the referenced resource. Should be empty for the cluster-scoped resources";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicy" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the ValidatingAdmissionPolicy.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicySpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBinding" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the ValidatingAdmissionPolicyBinding.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBindingSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBindingList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of PolicyBinding.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBinding")));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBindingSpec" = {

      options = {
        "matchResources" = mkOption {
          description = "MatchResources declares what resources match this binding and will be validated by it. Note that this is intersected with the policy's matchConstraints, so only requests that are matched by the policy can be selected by this. If this is unset, all resources matched by the policy are validated by this binding When resourceRules is unset, it does not constrain resource matching. If a resource is matched by the other fields of this object, it will be validated. Note that this is differs from ValidatingAdmissionPolicy matchConstraints, where resourceRules are required.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.MatchResources"));
        };
        "paramRef" = mkOption {
          description = "ParamRef specifies the parameter resource used to configure the admission control policy. It should point to a resource of the type specified in ParamKind of the bound ValidatingAdmissionPolicy. If the policy specifies a ParamKind and the resource referred to by ParamRef does not exist, this binding is considered mis-configured and the FailurePolicy of the ValidatingAdmissionPolicy applied.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ParamRef"));
        };
        "policyName" = mkOption {
          description = "PolicyName references a ValidatingAdmissionPolicy name which the ValidatingAdmissionPolicyBinding binds to. If the referenced resource does not exist, this binding is considered invalid and will be ignored Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "matchResources" = mkOverride 1002 null;
        "paramRef" = mkOverride 1002 null;
        "policyName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of ValidatingAdmissionPolicy.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicy")));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicySpec" = {

      options = {
        "failurePolicy" = mkOption {
          description = "FailurePolicy defines how to handle failures for the admission policy. Failures can occur from invalid or mis-configured policy definitions or bindings. A policy is invalid if spec.paramKind refers to a non-existent Kind. A binding is invalid if spec.paramRef.name refers to a non-existent resource. Allowed values are Ignore or Fail. Defaults to Fail.";
          type = (types.nullOr types.str);
        };
        "matchConstraints" = mkOption {
          description = "MatchConstraints specifies what resources this policy is designed to validate. The AdmissionPolicy cares about a request if it matches _all_ Constraints. However, in order to prevent clusters from being put into an unstable state that cannot be recovered from via the API ValidatingAdmissionPolicy cannot match ValidatingAdmissionPolicy and ValidatingAdmissionPolicyBinding. Required.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.MatchResources"));
        };
        "paramKind" = mkOption {
          description = "ParamKind specifies the kind of resources used to parameterize this policy. If absent, there are no parameters for this policy and the param CEL variable will not be provided to validation expressions. If ParamKind refers to a non-existent kind, this policy definition is mis-configured and the FailurePolicy is applied. If paramKind is specified but paramRef is unset in ValidatingAdmissionPolicyBinding, the params variable will be null.";
          type = (types.nullOr (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.ParamKind"));
        };
        "validations" = mkOption {
          description = "Validations contain CEL expressions which is used to apply the validation. A minimum of one validation is required for a policy definition. Required.";
          type = (types.listOf (submoduleOf "io.k8s.api.admissionregistration.v1alpha1.Validation"));
        };
      };


      config = {
        "failurePolicy" = mkOverride 1002 null;
        "matchConstraints" = mkOverride 1002 null;
        "paramKind" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.admissionregistration.v1alpha1.Validation" = {

      options = {
        "expression" = mkOption {
          description = "Expression represents the expression which will be evaluated by CEL. ref: https://github.com/google/cel-spec CEL expressions have access to the contents of the Admission request/response, organized into CEL variables as well as some other useful variables:\n\n'object' - The object from the incoming request. The value is null for DELETE requests. 'oldObject' - The existing object. The value is null for CREATE requests. 'request' - Attributes of the admission request([ref](/pkg/apis/admission/types.go#AdmissionRequest)). 'params' - Parameter resource referred to by the policy binding being evaluated. Only populated if the policy has a ParamKind.\n\nThe `apiVersion`, `kind`, `metadata.name` and `metadata.generateName` are always accessible from the root of the object. No other metadata properties are accessible.\n\nOnly property names of the form `[a-zA-Z_.-/][a-zA-Z0-9_.-/]*` are accessible. Accessible property names are escaped according to the following rules when accessed in the expression: - '__' escapes to '__underscores__' - '.' escapes to '__dot__' - '-' escapes to '__dash__' - '/' escapes to '__slash__' - Property names that exactly match a CEL RESERVED keyword escape to '__{keyword}__'. The keywords are:\n\t  \"true\", \"false\", \"null\", \"in\", \"as\", \"break\", \"const\", \"continue\", \"else\", \"for\", \"function\", \"if\",\n\t  \"import\", \"let\", \"loop\", \"package\", \"namespace\", \"return\".\nExamples:\n  - Expression accessing a property named \"namespace\": {\"Expression\": \"object.__namespace__ > 0\"}\n  - Expression accessing a property named \"x-prop\": {\"Expression\": \"object.x__dash__prop > 0\"}\n  - Expression accessing a property named \"redact__d\": {\"Expression\": \"object.redact__underscores__d > 0\"}\n\nEquality on arrays with list type of 'set' or 'map' ignores element order, i.e. [1, 2] == [2, 1]. Concatenation on arrays with x-kubernetes-list-type use the semantics of the list type:\n  - 'set': `X + Y` performs a union where the array positions of all elements in `X` are preserved and\n    non-intersecting elements in `Y` are appended, retaining their partial order.\n  - 'map': `X + Y` performs a merge where the array positions of all keys in `X` are preserved but the values\n    are overwritten by values in `Y` when the key sets of `X` and `Y` intersect. Elements in `Y` with\n    non-intersecting keys are appended, retaining their partial order.\nRequired.";
          type = types.str;
        };
        "message" = mkOption {
          description = "Message represents the message displayed when validation fails. The message is required if the Expression contains line breaks. The message must not contain line breaks. If unset, the message is \"failed rule: {Rule}\". e.g. \"must be a URL with the host matching spec.host\" If the Expression contains line breaks. Message is required. The message must not contain line breaks. If unset, the message is \"failed Expression: {Expression}\".";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "Reason represents a machine-readable description of why this validation failed. If this is the first validation in the list to fail, this reason, as well as the corresponding HTTP response code, are used in the HTTP response to the client. The currently supported reasons are: \"Unauthorized\", \"Forbidden\", \"Invalid\", \"RequestEntityTooLarge\". If not set, StatusReasonInvalid is used in the response to the client.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apiserverinternal.v1alpha1.ServerStorageVersion" = {

      options = {
        "apiServerID" = mkOption {
          description = "The ID of the reporting API server.";
          type = (types.nullOr types.str);
        };
        "decodableVersions" = mkOption {
          description = "The API server can decode objects encoded in these versions. The encodingVersion must be included in the decodableVersions.";
          type = (types.nullOr (types.listOf types.str));
        };
        "encodingVersion" = mkOption {
          description = "The API server encodes the object to this version when persisting it in the backend (e.g., etcd).";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiServerID" = mkOverride 1002 null;
        "decodableVersions" = mkOverride 1002 null;
        "encodingVersion" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apiserverinternal.v1alpha1.StorageVersion" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "The name is <group>.<resource>.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec is an empty spec. It is here to comply with Kubernetes API style.";
          type = (submoduleOf "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionSpec");
        };
        "status" = mkOption {
          description = "API server instances report the version they can decode and the version they encode objects to when persisting objects in the backend.";
          type = (submoduleOf "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionStatus");
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "If set, this represents the .metadata.generation that the condition was set based upon.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = types.str;
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of the condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items holds a list of StorageVersion";
          type = (types.listOf (submoduleOf "io.k8s.api.apiserverinternal.v1alpha1.StorageVersion"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionSpec" = { };
    "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionStatus" = {

      options = {
        "commonEncodingVersion" = mkOption {
          description = "If all API server instances agree on the same encoding storage version, then this field is set to that version. Otherwise this field is left empty. API servers should finish updating its storageVersionStatus entry before serving write operations, so that this field will be in sync with the reality.";
          type = (types.nullOr types.str);
        };
        "conditions" = mkOption {
          description = "The latest available observations of the storageVersion's state.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.apiserverinternal.v1alpha1.StorageVersionCondition")));
        };
        "storageVersions" = mkOption {
          description = "The reported versions per API server instance.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.apiserverinternal.v1alpha1.ServerStorageVersion")));
        };
      };


      config = {
        "commonEncodingVersion" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "storageVersions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ControllerRevision" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "data" = mkOption {
          description = "Data is the serialized representation of the state.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.runtime.RawExtension"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "revision" = mkOption {
          description = "Revision indicates the revision of the state represented by Data.";
          type = types.int;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "data" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ControllerRevisionList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of ControllerRevisions";
          type = (types.listOf (submoduleOf "io.k8s.api.apps.v1.ControllerRevision"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSet" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "The desired behavior of this daemon set. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DaemonSetSpec"));
        };
        "status" = mkOption {
          description = "The current status of this daemon set. This data may be out of date by some window of time. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DaemonSetStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSetCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of DaemonSet condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSetList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "A list of daemon sets.";
          type = (types.listOf (submoduleOf "io.k8s.api.apps.v1.DaemonSet"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSetSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "The minimum number of seconds for which a newly created DaemonSet pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready).";
          type = (types.nullOr types.int);
        };
        "revisionHistoryLimit" = mkOption {
          description = "The number of old history to retain to allow rollback. This is a pointer to distinguish between explicit zero and not specified. Defaults to 10.";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "A label query over pods that are managed by the daemon set. Must match in order to be controlled. It must match the pod template's labels. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector");
        };
        "template" = mkOption {
          description = "An object that describes the pod that will be created. The DaemonSet will create exactly one copy of this pod on every node that matches the template's node selector (or on every node if no node selector is specified). More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#pod-template";
          type = (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec");
        };
        "updateStrategy" = mkOption {
          description = "An update strategy to replace existing DaemonSet pods with new pods.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DaemonSetUpdateStrategy"));
        };
      };


      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "revisionHistoryLimit" = mkOverride 1002 null;
        "updateStrategy" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSetStatus" = {

      options = {
        "collisionCount" = mkOption {
          description = "Count of hash collisions for the DaemonSet. The DaemonSet controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ControllerRevision.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Represents the latest available observations of a DaemonSet's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.apps.v1.DaemonSetCondition" "type"));
          apply = attrsToList;
        };
        "currentNumberScheduled" = mkOption {
          description = "The number of nodes that are running at least 1 daemon pod and are supposed to run the daemon pod. More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/";
          type = types.int;
        };
        "desiredNumberScheduled" = mkOption {
          description = "The total number of nodes that should be running the daemon pod (including nodes correctly running the daemon pod). More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/";
          type = types.int;
        };
        "numberAvailable" = mkOption {
          description = "The number of nodes that should be running the daemon pod and have one or more of the daemon pod running and available (ready for at least spec.minReadySeconds)";
          type = (types.nullOr types.int);
        };
        "numberMisscheduled" = mkOption {
          description = "The number of nodes that are running the daemon pod, but are not supposed to run the daemon pod. More info: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/";
          type = types.int;
        };
        "numberReady" = mkOption {
          description = "numberReady is the number of nodes that should be running the daemon pod and have one or more of the daemon pod running with a Ready Condition.";
          type = types.int;
        };
        "numberUnavailable" = mkOption {
          description = "The number of nodes that should be running the daemon pod and have none of the daemon pod running and available (ready for at least spec.minReadySeconds)";
          type = (types.nullOr types.int);
        };
        "observedGeneration" = mkOption {
          description = "The most recent generation observed by the daemon set controller.";
          type = (types.nullOr types.int);
        };
        "updatedNumberScheduled" = mkOption {
          description = "The total number of nodes that are running updated daemon pod";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "collisionCount" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "numberAvailable" = mkOverride 1002 null;
        "numberUnavailable" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "updatedNumberScheduled" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DaemonSetUpdateStrategy" = {

      options = {
        "rollingUpdate" = mkOption {
          description = "Rolling update config params. Present only if type = \"RollingUpdate\".";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.RollingUpdateDaemonSet"));
        };
        "type" = mkOption {
          description = "Type of daemon set update. Can be \"RollingUpdate\" or \"OnDelete\". Default is RollingUpdate.\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "rollingUpdate" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.Deployment" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the Deployment.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DeploymentSpec"));
        };
        "status" = mkOption {
          description = "Most recently observed status of the Deployment.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DeploymentStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DeploymentCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "lastUpdateTime" = mkOption {
          description = "The last time this condition was updated.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of deployment condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "lastUpdateTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DeploymentList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of Deployments.";
          type = (types.listOf (submoduleOf "io.k8s.api.apps.v1.Deployment"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DeploymentSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "Minimum number of seconds for which a newly created pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready)";
          type = (types.nullOr types.int);
        };
        "paused" = mkOption {
          description = "Indicates that the deployment is paused.";
          type = (types.nullOr types.bool);
        };
        "progressDeadlineSeconds" = mkOption {
          description = "The maximum time in seconds for a deployment to make progress before it is considered to be failed. The deployment controller will continue to process failed deployments and a condition with a ProgressDeadlineExceeded reason will be surfaced in the deployment status. Note that progress will not be estimated during the time a deployment is paused. Defaults to 600s.";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Number of desired pods. This is a pointer to distinguish between explicit zero and not specified. Defaults to 1.";
          type = (types.nullOr types.int);
        };
        "revisionHistoryLimit" = mkOption {
          description = "The number of old ReplicaSets to retain to allow rollback. This is a pointer to distinguish between explicit zero and not specified. Defaults to 10.";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "Label selector for pods. Existing ReplicaSets whose pods are selected by this will be the ones affected by this deployment. It must match the pod template's labels.";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector");
        };
        "strategy" = mkOption {
          description = "The deployment strategy to use to replace existing pods with new ones.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.DeploymentStrategy"));
        };
        "template" = mkOption {
          description = "Template describes the pods that will be created.";
          type = (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec");
        };
      };


      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "paused" = mkOverride 1002 null;
        "progressDeadlineSeconds" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "revisionHistoryLimit" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DeploymentStatus" = {

      options = {
        "availableReplicas" = mkOption {
          description = "Total number of available pods (ready for at least minReadySeconds) targeted by this deployment.";
          type = (types.nullOr types.int);
        };
        "collisionCount" = mkOption {
          description = "Count of hash collisions for the Deployment. The Deployment controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ReplicaSet.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Represents the latest available observations of a deployment's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.apps.v1.DeploymentCondition" "type"));
          apply = attrsToList;
        };
        "observedGeneration" = mkOption {
          description = "The generation observed by the deployment controller.";
          type = (types.nullOr types.int);
        };
        "readyReplicas" = mkOption {
          description = "readyReplicas is the number of pods targeted by this Deployment with a Ready Condition.";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Total number of non-terminated pods targeted by this deployment (their labels match the selector).";
          type = (types.nullOr types.int);
        };
        "unavailableReplicas" = mkOption {
          description = "Total number of unavailable pods targeted by this deployment. This is the total number of pods that are still required for the deployment to have 100% available capacity. They may either be pods that are running but not yet available or pods that still have not been created.";
          type = (types.nullOr types.int);
        };
        "updatedReplicas" = mkOption {
          description = "Total number of non-terminated pods targeted by this deployment that have the desired template spec.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "availableReplicas" = mkOverride 1002 null;
        "collisionCount" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "readyReplicas" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "unavailableReplicas" = mkOverride 1002 null;
        "updatedReplicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.DeploymentStrategy" = {

      options = {
        "rollingUpdate" = mkOption {
          description = "Rolling update config params. Present only if DeploymentStrategyType = RollingUpdate.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.RollingUpdateDeployment"));
        };
        "type" = mkOption {
          description = "Type of deployment. Can be \"Recreate\" or \"RollingUpdate\". Default is RollingUpdate.\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "rollingUpdate" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ReplicaSet" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "If the Labels of a ReplicaSet are empty, they are defaulted to be the same as the Pod(s) that the ReplicaSet manages. Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the specification of the desired behavior of the ReplicaSet. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.ReplicaSetSpec"));
        };
        "status" = mkOption {
          description = "Status is the most recently observed status of the ReplicaSet. This data may be out of date by some window of time. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.ReplicaSetStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ReplicaSetCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "The last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of replica set condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ReplicaSetList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of ReplicaSets. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller";
          type = (types.listOf (submoduleOf "io.k8s.api.apps.v1.ReplicaSet"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ReplicaSetSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "Minimum number of seconds for which a newly created pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready)";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Replicas is the number of desired replicas. This is a pointer to distinguish between explicit zero and unspecified. Defaults to 1. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#what-is-a-replicationcontroller";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "Selector is a label query over pods that should match the replica count. Label keys and values that must match in order to be controlled by this replica set. It must match the pod template's labels. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector");
        };
        "template" = mkOption {
          description = "Template is the object that describes the pod that will be created if insufficient replicas are detected. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#pod-template";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec"));
        };
      };


      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.ReplicaSetStatus" = {

      options = {
        "availableReplicas" = mkOption {
          description = "The number of available replicas (ready for at least minReadySeconds) for this replica set.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Represents the latest available observations of a replica set's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.apps.v1.ReplicaSetCondition" "type"));
          apply = attrsToList;
        };
        "fullyLabeledReplicas" = mkOption {
          description = "The number of pods that have labels matching the labels of the pod template of the replicaset.";
          type = (types.nullOr types.int);
        };
        "observedGeneration" = mkOption {
          description = "ObservedGeneration reflects the generation of the most recently observed ReplicaSet.";
          type = (types.nullOr types.int);
        };
        "readyReplicas" = mkOption {
          description = "readyReplicas is the number of pods targeted by this ReplicaSet with a Ready Condition.";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Replicas is the most recently observed number of replicas. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/#what-is-a-replicationcontroller";
          type = types.int;
        };
      };


      config = {
        "availableReplicas" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "fullyLabeledReplicas" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "readyReplicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.RollingUpdateDaemonSet" = {

      options = {
        "maxSurge" = mkOption {
          description = "The maximum number of nodes with an existing available DaemonSet pod that can have an updated DaemonSet pod during during an update. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). This can not be 0 if MaxUnavailable is 0. Absolute number is calculated from percentage by rounding up to a minimum of 1. Default value is 0. Example: when this is set to 30%, at most 30% of the total number of nodes that should be running the daemon pod (i.e. status.desiredNumberScheduled) can have their a new pod created before the old pod is marked as deleted. The update starts by launching new pods on 30% of nodes. Once an updated pod is available (Ready for at least minReadySeconds) the old DaemonSet pod on that node is marked deleted. If the old pod becomes unavailable for any reason (Ready transitions to false, is evicted, or is drained) an updated pod is immediatedly created on that node without considering surge limits. Allowing surge implies the possibility that the resources consumed by the daemonset on any given node can double if the readiness check fails, and so resource intensive daemonsets should take into account that they may cause evictions during disruption.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "maxUnavailable" = mkOption {
          description = "The maximum number of DaemonSet pods that can be unavailable during the update. Value can be an absolute number (ex: 5) or a percentage of total number of DaemonSet pods at the start of the update (ex: 10%). Absolute number is calculated from percentage by rounding up. This cannot be 0 if MaxSurge is 0 Default value is 1. Example: when this is set to 30%, at most 30% of the total number of nodes that should be running the daemon pod (i.e. status.desiredNumberScheduled) can have their pods stopped for an update at any given time. The update starts by stopping at most 30% of those DaemonSet pods and then brings up new DaemonSet pods in their place. Once the new pods are available, it then proceeds onto other DaemonSet pods, thus ensuring that at least 70% of original number of DaemonSet pods are available at all times during the update.";
          type = (types.nullOr (types.either types.int types.str));
        };
      };


      config = {
        "maxSurge" = mkOverride 1002 null;
        "maxUnavailable" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.RollingUpdateDeployment" = {

      options = {
        "maxSurge" = mkOption {
          description = "The maximum number of pods that can be scheduled above the desired number of pods. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). This can not be 0 if MaxUnavailable is 0. Absolute number is calculated from percentage by rounding up. Defaults to 25%. Example: when this is set to 30%, the new ReplicaSet can be scaled up immediately when the rolling update starts, such that the total number of old and new pods do not exceed 130% of desired pods. Once old pods have been killed, new ReplicaSet can be scaled up further, ensuring that total number of pods running at any time during the update is at most 130% of desired pods.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "maxUnavailable" = mkOption {
          description = "The maximum number of pods that can be unavailable during the update. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). Absolute number is calculated from percentage by rounding down. This can not be 0 if MaxSurge is 0. Defaults to 25%. Example: when this is set to 30%, the old ReplicaSet can be scaled down to 70% of desired pods immediately when the rolling update starts. Once new pods are ready, old ReplicaSet can be scaled down further, followed by scaling up the new ReplicaSet, ensuring that the total number of pods available at all times during the update is at least 70% of desired pods.";
          type = (types.nullOr (types.either types.int types.str));
        };
      };


      config = {
        "maxSurge" = mkOverride 1002 null;
        "maxUnavailable" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.RollingUpdateStatefulSetStrategy" = {

      options = {
        "maxUnavailable" = mkOption {
          description = "The maximum number of pods that can be unavailable during the update. Value can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%). Absolute number is calculated from percentage by rounding up. This can not be 0. Defaults to 1. This field is alpha-level and is only honored by servers that enable the MaxUnavailableStatefulSet feature. The field applies to all pods in the range 0 to Replicas-1. That means if there is any unavailable pod in the range 0 to Replicas-1, it will be counted towards MaxUnavailable.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "partition" = mkOption {
          description = "Partition indicates the ordinal at which the StatefulSet should be partitioned for updates. During a rolling update, all pods from ordinal Replicas-1 to Partition are updated. All pods from ordinal Partition-1 to 0 remain untouched. This is helpful in being able to do a canary based deployment. The default value is 0.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "maxUnavailable" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSet" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the desired identities of pods in this set.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.StatefulSetSpec"));
        };
        "status" = mkOption {
          description = "Status is the current status of Pods in this StatefulSet. This data may be out of date by some window of time.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.StatefulSetStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of statefulset condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of stateful sets.";
          type = (types.listOf (submoduleOf "io.k8s.api.apps.v1.StatefulSet"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetOrdinals" = {

      options = {
        "start" = mkOption {
          description = "start is the number representing the first replica's index. It may be used to number replicas from an alternate index (eg: 1-indexed) over the default 0-indexed names, or to orchestrate progressive movement of replicas from one StatefulSet to another. If set, replica indices will be in the range:\n  [.spec.ordinals.start, .spec.ordinals.start + .spec.replicas).\nIf unset, defaults to 0. Replica indices will be in the range:\n  [0, .spec.replicas).";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "start" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetPersistentVolumeClaimRetentionPolicy" = {

      options = {
        "whenDeleted" = mkOption {
          description = "WhenDeleted specifies what happens to PVCs created from StatefulSet VolumeClaimTemplates when the StatefulSet is deleted. The default policy of `Retain` causes PVCs to not be affected by StatefulSet deletion. The `Delete` policy causes those PVCs to be deleted.";
          type = (types.nullOr types.str);
        };
        "whenScaled" = mkOption {
          description = "WhenScaled specifies what happens to PVCs created from StatefulSet VolumeClaimTemplates when the StatefulSet is scaled down. The default policy of `Retain` causes PVCs to not be affected by a scaledown. The `Delete` policy causes the associated PVCs for any excess pods above the replica count to be deleted.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "whenDeleted" = mkOverride 1002 null;
        "whenScaled" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "Minimum number of seconds for which a newly created pod should be ready without any of its container crashing for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready)";
          type = (types.nullOr types.int);
        };
        "ordinals" = mkOption {
          description = "ordinals controls the numbering of replica indices in a StatefulSet. The default ordinals behavior assigns a \"0\" index to the first replica and increments the index by one for each additional replica requested. Using the ordinals field requires the StatefulSetStartOrdinal feature gate to be enabled, which is alpha.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.StatefulSetOrdinals"));
        };
        "persistentVolumeClaimRetentionPolicy" = mkOption {
          description = "persistentVolumeClaimRetentionPolicy describes the lifecycle of persistent volume claims created from volumeClaimTemplates. By default, all persistent volume claims are created as needed and retained until manually deleted. This policy allows the lifecycle to be altered, for example by deleting persistent volume claims when their stateful set is deleted, or when their pod is scaled down. This requires the StatefulSetAutoDeletePVC feature gate to be enabled, which is alpha.  +optional";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.StatefulSetPersistentVolumeClaimRetentionPolicy"));
        };
        "podManagementPolicy" = mkOption {
          description = "podManagementPolicy controls how pods are created during initial scale up, when replacing pods on nodes, or when scaling down. The default policy is `OrderedReady`, where pods are created in increasing order (pod-0, then pod-1, etc) and the controller will wait until each pod is ready before continuing. When scaling down, the pods are removed in the opposite order. The alternative policy is `Parallel` which will create pods in parallel to match the desired scale without waiting, and on scale down will delete all pods at once.\n\n";
          type = (types.nullOr types.str);
        };
        "replicas" = mkOption {
          description = "replicas is the desired number of replicas of the given Template. These are replicas in the sense that they are instantiations of the same Template, but individual replicas also have a consistent identity. If unspecified, defaults to 1.";
          type = (types.nullOr types.int);
        };
        "revisionHistoryLimit" = mkOption {
          description = "revisionHistoryLimit is the maximum number of revisions that will be maintained in the StatefulSet's revision history. The revision history consists of all revisions not represented by a currently applied StatefulSetSpec version. The default value is 10.";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "selector is a label query over pods that should match the replica count. It must match the pod template's labels. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector");
        };
        "serviceName" = mkOption {
          description = "serviceName is the name of the service that governs this StatefulSet. This service must exist before the StatefulSet, and is responsible for the network identity of the set. Pods get DNS/hostnames that follow the pattern: pod-specific-string.serviceName.default.svc.cluster.local where \"pod-specific-string\" is managed by the StatefulSet controller.";
          type = types.str;
        };
        "template" = mkOption {
          description = "template is the object that describes the pod that will be created if insufficient replicas are detected. Each pod stamped out by the StatefulSet will fulfill this Template, but have a unique identity from the rest of the StatefulSet. Each pod will be named with the format <statefulsetname>-<podindex>. For example, a pod in a StatefulSet named \"web\" with index number \"3\" would be named \"web-3\".";
          type = (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec");
        };
        "updateStrategy" = mkOption {
          description = "updateStrategy indicates the StatefulSetUpdateStrategy that will be employed to update Pods in the StatefulSet when a revision is made to Template.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.StatefulSetUpdateStrategy"));
        };
        "volumeClaimTemplates" = mkOption {
          description = "volumeClaimTemplates is a list of claims that pods are allowed to reference. The StatefulSet controller is responsible for mapping network identities to claims in a way that maintains the identity of a pod. Every claim in this list must have at least one matching (by name) volumeMount in one container in the template. A claim in this list takes precedence over any volumes in the template, with the same name.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaim")));
        };
      };


      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "ordinals" = mkOverride 1002 null;
        "persistentVolumeClaimRetentionPolicy" = mkOverride 1002 null;
        "podManagementPolicy" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "revisionHistoryLimit" = mkOverride 1002 null;
        "updateStrategy" = mkOverride 1002 null;
        "volumeClaimTemplates" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetStatus" = {

      options = {
        "availableReplicas" = mkOption {
          description = "Total number of available pods (ready for at least minReadySeconds) targeted by this statefulset.";
          type = (types.nullOr types.int);
        };
        "collisionCount" = mkOption {
          description = "collisionCount is the count of hash collisions for the StatefulSet. The StatefulSet controller uses this field as a collision avoidance mechanism when it needs to create the name for the newest ControllerRevision.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Represents the latest available observations of a statefulset's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.apps.v1.StatefulSetCondition" "type"));
          apply = attrsToList;
        };
        "currentReplicas" = mkOption {
          description = "currentReplicas is the number of Pods created by the StatefulSet controller from the StatefulSet version indicated by currentRevision.";
          type = (types.nullOr types.int);
        };
        "currentRevision" = mkOption {
          description = "currentRevision, if not empty, indicates the version of the StatefulSet used to generate Pods in the sequence [0,currentReplicas).";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration is the most recent generation observed for this StatefulSet. It corresponds to the StatefulSet's generation, which is updated on mutation by the API Server.";
          type = (types.nullOr types.int);
        };
        "readyReplicas" = mkOption {
          description = "readyReplicas is the number of pods created for this StatefulSet with a Ready Condition.";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "replicas is the number of Pods created by the StatefulSet controller.";
          type = types.int;
        };
        "updateRevision" = mkOption {
          description = "updateRevision, if not empty, indicates the version of the StatefulSet used to generate Pods in the sequence [replicas-updatedReplicas,replicas)";
          type = (types.nullOr types.str);
        };
        "updatedReplicas" = mkOption {
          description = "updatedReplicas is the number of Pods created by the StatefulSet controller from the StatefulSet version indicated by updateRevision.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "availableReplicas" = mkOverride 1002 null;
        "collisionCount" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "currentReplicas" = mkOverride 1002 null;
        "currentRevision" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "readyReplicas" = mkOverride 1002 null;
        "updateRevision" = mkOverride 1002 null;
        "updatedReplicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.apps.v1.StatefulSetUpdateStrategy" = {

      options = {
        "rollingUpdate" = mkOption {
          description = "RollingUpdate is used to communicate parameters when Type is RollingUpdateStatefulSetStrategyType.";
          type = (types.nullOr (submoduleOf "io.k8s.api.apps.v1.RollingUpdateStatefulSetStrategy"));
        };
        "type" = mkOption {
          description = "Type indicates the type of the StatefulSetUpdateStrategy. Default is RollingUpdate.\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "rollingUpdate" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.BoundObjectReference" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of the referent. Valid kinds are 'Pod' and 'Secret'.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent.";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "UID of the referent.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.TokenRequest" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated";
          type = (submoduleOf "io.k8s.api.authentication.v1.TokenRequestSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates whether the token can be authenticated.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1.TokenRequestStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.TokenRequestSpec" = {

      options = {
        "audiences" = mkOption {
          description = "Audiences are the intendend audiences of the token. A recipient of a token must identify themself with an identifier in the list of audiences of the token, and otherwise should reject the token. A token issued for multiple audiences may be used to authenticate against any of the audiences listed but implies a high degree of trust between the target audiences.";
          type = (types.listOf types.str);
        };
        "boundObjectRef" = mkOption {
          description = "BoundObjectRef is a reference to an object that the token will be bound to. The token will only be valid for as long as the bound object exists. NOTE: The API server's TokenReview endpoint will validate the BoundObjectRef, but other audiences may not. Keep ExpirationSeconds small if you want prompt revocation.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1.BoundObjectReference"));
        };
        "expirationSeconds" = mkOption {
          description = "ExpirationSeconds is the requested duration of validity of the request. The token issuer may return a token with a different validity duration so a client needs to check the 'expiration' field in a response.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "boundObjectRef" = mkOverride 1002 null;
        "expirationSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.TokenRequestStatus" = {

      options = {
        "expirationTimestamp" = mkOption {
          description = "ExpirationTimestamp is the time of expiration of the returned token.";
          type = types.str;
        };
        "token" = mkOption {
          description = "Token is the opaque bearer token.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.authentication.v1.TokenReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated";
          type = (submoduleOf "io.k8s.api.authentication.v1.TokenReviewSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates whether the request can be authenticated.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1.TokenReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.TokenReviewSpec" = {

      options = {
        "audiences" = mkOption {
          description = "Audiences is a list of the identifiers that the resource server presented with the token identifies as. Audience-aware token authenticators will verify that the token was intended for at least one of the audiences in this list. If no audiences are provided, the audience will default to the audience of the Kubernetes apiserver.";
          type = (types.nullOr (types.listOf types.str));
        };
        "token" = mkOption {
          description = "Token is the opaque bearer token.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "audiences" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.TokenReviewStatus" = {

      options = {
        "audiences" = mkOption {
          description = "Audiences are audience identifiers chosen by the authenticator that are compatible with both the TokenReview and token. An identifier is any identifier in the intersection of the TokenReviewSpec audiences and the token's audiences. A client of the TokenReview API that sets the spec.audiences field should validate that a compatible audience identifier is returned in the status.audiences field to ensure that the TokenReview server is audience aware. If a TokenReview returns an empty status.audience field where status.authenticated is \"true\", the token is valid against the audience of the Kubernetes API server.";
          type = (types.nullOr (types.listOf types.str));
        };
        "authenticated" = mkOption {
          description = "Authenticated indicates that the token was associated with a known user.";
          type = (types.nullOr types.bool);
        };
        "error" = mkOption {
          description = "Error indicates that the token couldn't be checked";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is the UserInfo associated with the provided token.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1.UserInfo"));
        };
      };


      config = {
        "audiences" = mkOverride 1002 null;
        "authenticated" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1.UserInfo" = {

      options = {
        "extra" = mkOption {
          description = "Any additional information provided by the authenticator.";
          type = (types.nullOr (types.loaOf types.str));
        };
        "groups" = mkOption {
          description = "The names of groups this user is a part of.";
          type = (types.nullOr (types.listOf types.str));
        };
        "uid" = mkOption {
          description = "A unique value that identifies this user across time. If this user is deleted and another user by the same name is added, they will have different UIDs.";
          type = (types.nullOr types.str);
        };
        "username" = mkOption {
          description = "The name that uniquely identifies this user among all active users.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "extra" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1alpha1.SelfSubjectReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "status" = mkOption {
          description = "Status is filled in by the server with the user attributes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1alpha1.SelfSubjectReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authentication.v1alpha1.SelfSubjectReviewStatus" = {

      options = {
        "userInfo" = mkOption {
          description = "User attributes of the user making this request.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authentication.v1.UserInfo"));
        };
      };


      config = {
        "userInfo" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.LocalSubjectAccessReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated.  spec.namespace must be equal to the namespace you made the request against.  If empty, it is defaulted.";
          type = (submoduleOf "io.k8s.api.authorization.v1.SubjectAccessReviewSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates whether the request is allowed or not";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.SubjectAccessReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.NonResourceAttributes" = {

      options = {
        "path" = mkOption {
          description = "Path is the URL path of the request";
          type = (types.nullOr types.str);
        };
        "verb" = mkOption {
          description = "Verb is the standard HTTP verb";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "path" = mkOverride 1002 null;
        "verb" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.NonResourceRule" = {

      options = {
        "nonResourceURLs" = mkOption {
          description = "NonResourceURLs is a set of partial urls that a user should have access to.  *s are allowed, but only as the full, final step in the path.  \"*\" means all.";
          type = (types.nullOr (types.listOf types.str));
        };
        "verbs" = mkOption {
          description = "Verb is a list of kubernetes non-resource API verbs, like: get, post, put, delete, patch, head, options.  \"*\" means all.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "nonResourceURLs" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.ResourceAttributes" = {

      options = {
        "group" = mkOption {
          description = "Group is the API Group of the Resource.  \"*\" means all.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name is the name of the resource being requested for a \"get\" or deleted for a \"delete\". \"\" (empty) means all.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the action being requested.  Currently, there is no distinction between no namespace and all namespaces \"\" (empty) is defaulted for LocalSubjectAccessReviews \"\" (empty) is empty for cluster-scoped resources \"\" (empty) means \"all\" for namespace scoped resources from a SubjectAccessReview or SelfSubjectAccessReview";
          type = (types.nullOr types.str);
        };
        "resource" = mkOption {
          description = "Resource is one of the existing resource types.  \"*\" means all.";
          type = (types.nullOr types.str);
        };
        "subresource" = mkOption {
          description = "Subresource is one of the existing resource types.  \"\" means none.";
          type = (types.nullOr types.str);
        };
        "verb" = mkOption {
          description = "Verb is a kubernetes resource API verb, like: get, list, watch, create, update, delete, proxy.  \"*\" means all.";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Version is the API Version of the Resource.  \"*\" means all.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "group" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "resource" = mkOverride 1002 null;
        "subresource" = mkOverride 1002 null;
        "verb" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.ResourceRule" = {

      options = {
        "apiGroups" = mkOption {
          description = "APIGroups is the name of the APIGroup that contains the resources.  If multiple API groups are specified, any action requested against one of the enumerated resources in any API group will be allowed.  \"*\" means all.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resourceNames" = mkOption {
          description = "ResourceNames is an optional white list of names that the rule applies to.  An empty set means that everything is allowed.  \"*\" means all.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "Resources is a list of resources this rule applies to.  \"*\" means all in the specified apiGroups.\n \"*/foo\" represents the subresource 'foo' for all resources in the specified apiGroups.";
          type = (types.nullOr (types.listOf types.str));
        };
        "verbs" = mkOption {
          description = "Verb is a list of kubernetes resource API verbs, like: get, list, watch, create, update, delete, proxy.  \"*\" means all.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "apiGroups" = mkOverride 1002 null;
        "resourceNames" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SelfSubjectAccessReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated.  user and groups must be empty";
          type = (submoduleOf "io.k8s.api.authorization.v1.SelfSubjectAccessReviewSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates whether the request is allowed or not";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.SubjectAccessReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SelfSubjectAccessReviewSpec" = {

      options = {
        "nonResourceAttributes" = mkOption {
          description = "NonResourceAttributes describes information for a non-resource access request";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.NonResourceAttributes"));
        };
        "resourceAttributes" = mkOption {
          description = "ResourceAuthorizationAttributes describes information for a resource access request";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.ResourceAttributes"));
        };
      };


      config = {
        "nonResourceAttributes" = mkOverride 1002 null;
        "resourceAttributes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SelfSubjectRulesReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated.";
          type = (submoduleOf "io.k8s.api.authorization.v1.SelfSubjectRulesReviewSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates the set of actions a user can perform.";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.SubjectRulesReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SelfSubjectRulesReviewSpec" = {

      options = {
        "namespace" = mkOption {
          description = "Namespace to evaluate rules for. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SubjectAccessReview" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec holds information about the request being evaluated";
          type = (submoduleOf "io.k8s.api.authorization.v1.SubjectAccessReviewSpec");
        };
        "status" = mkOption {
          description = "Status is filled in by the server and indicates whether the request is allowed or not";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.SubjectAccessReviewStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SubjectAccessReviewSpec" = {

      options = {
        "extra" = mkOption {
          description = "Extra corresponds to the user.Info.GetExtra() method from the authenticator.  Since that is input to the authorizer it needs a reflection here.";
          type = (types.nullOr (types.loaOf types.str));
        };
        "groups" = mkOption {
          description = "Groups is the groups you're testing for.";
          type = (types.nullOr (types.listOf types.str));
        };
        "nonResourceAttributes" = mkOption {
          description = "NonResourceAttributes describes information for a non-resource access request";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.NonResourceAttributes"));
        };
        "resourceAttributes" = mkOption {
          description = "ResourceAuthorizationAttributes describes information for a resource access request";
          type = (types.nullOr (submoduleOf "io.k8s.api.authorization.v1.ResourceAttributes"));
        };
        "uid" = mkOption {
          description = "UID information about the requesting user.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is the user you're testing for. If you specify \"User\" but not \"Groups\", then is it interpreted as \"What if User were not a member of any groups";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "extra" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "nonResourceAttributes" = mkOverride 1002 null;
        "resourceAttributes" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SubjectAccessReviewStatus" = {

      options = {
        "allowed" = mkOption {
          description = "Allowed is required. True if the action would be allowed, false otherwise.";
          type = types.bool;
        };
        "denied" = mkOption {
          description = "Denied is optional. True if the action would be denied, otherwise false. If both allowed is false and denied is false, then the authorizer has no opinion on whether to authorize the action. Denied may not be true if Allowed is true.";
          type = (types.nullOr types.bool);
        };
        "evaluationError" = mkOption {
          description = "EvaluationError is an indication that some error occurred during the authorization check. It is entirely possible to get an error and be able to continue determine authorization status in spite of it. For instance, RBAC can be missing a role, but enough roles are still present and bound to reason about the request.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "Reason is optional.  It indicates why a request was allowed or denied.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "denied" = mkOverride 1002 null;
        "evaluationError" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.authorization.v1.SubjectRulesReviewStatus" = {

      options = {
        "evaluationError" = mkOption {
          description = "EvaluationError can appear in combination with Rules. It indicates an error occurred during rule evaluation, such as an authorizer that doesn't support rule evaluation, and that ResourceRules and/or NonResourceRules may be incomplete.";
          type = (types.nullOr types.str);
        };
        "incomplete" = mkOption {
          description = "Incomplete is true when the rules returned by this call are incomplete. This is most commonly encountered when an authorizer, such as an external authorizer, doesn't support rules evaluation.";
          type = types.bool;
        };
        "nonResourceRules" = mkOption {
          description = "NonResourceRules is the list of actions the subject is allowed to perform on non-resources. The list ordering isn't significant, may contain duplicates, and possibly be incomplete.";
          type = (types.listOf (submoduleOf "io.k8s.api.authorization.v1.NonResourceRule"));
        };
        "resourceRules" = mkOption {
          description = "ResourceRules is the list of actions the subject is allowed to perform on resources. The list ordering isn't significant, may contain duplicates, and possibly be incomplete.";
          type = (types.listOf (submoduleOf "io.k8s.api.authorization.v1.ResourceRule"));
        };
      };


      config = {
        "evaluationError" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.CrossVersionObjectReference" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of the referent; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent; More info: http://kubernetes.io/docs/user-guide/identifiers#names";
          type = types.str;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.HorizontalPodAutoscaler" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "behaviour of autoscaler. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v1.HorizontalPodAutoscalerSpec"));
        };
        "status" = mkOption {
          description = "current information about the autoscaler.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v1.HorizontalPodAutoscalerStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.HorizontalPodAutoscalerList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "list of horizontal pod autoscaler objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.autoscaling.v1.HorizontalPodAutoscaler"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.HorizontalPodAutoscalerSpec" = {

      options = {
        "maxReplicas" = mkOption {
          description = "upper limit for the number of pods that can be set by the autoscaler; cannot be smaller than MinReplicas.";
          type = types.int;
        };
        "minReplicas" = mkOption {
          description = "minReplicas is the lower limit for the number of replicas to which the autoscaler can scale down.  It defaults to 1 pod.  minReplicas is allowed to be 0 if the alpha feature gate HPAScaleToZero is enabled and at least one Object or External metric is configured.  Scaling is active as long as at least one metric value is available.";
          type = (types.nullOr types.int);
        };
        "scaleTargetRef" = mkOption {
          description = "reference to scaled resource; horizontal pod autoscaler will learn the current resource consumption and will set the desired number of pods by using its Scale subresource.";
          type = (submoduleOf "io.k8s.api.autoscaling.v1.CrossVersionObjectReference");
        };
        "targetCPUUtilizationPercentage" = mkOption {
          description = "target average CPU utilization (represented as a percentage of requested CPU) over all the pods; if not specified the default autoscaling policy will be used.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "minReplicas" = mkOverride 1002 null;
        "targetCPUUtilizationPercentage" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.HorizontalPodAutoscalerStatus" = {

      options = {
        "currentCPUUtilizationPercentage" = mkOption {
          description = "current average CPU utilization over all pods, represented as a percentage of requested CPU, e.g. 70 means that an average pod is using now 70% of its requested CPU.";
          type = (types.nullOr types.int);
        };
        "currentReplicas" = mkOption {
          description = "current number of replicas of pods managed by this autoscaler.";
          type = types.int;
        };
        "desiredReplicas" = mkOption {
          description = "desired number of replicas of pods managed by this autoscaler.";
          type = types.int;
        };
        "lastScaleTime" = mkOption {
          description = "last time the HorizontalPodAutoscaler scaled the number of pods; used by the autoscaler to control how often the number of pods is changed.";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "most recent generation observed by this autoscaler.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "currentCPUUtilizationPercentage" = mkOverride 1002 null;
        "lastScaleTime" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.Scale" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "defines the behavior of the scale. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v1.ScaleSpec"));
        };
        "status" = mkOption {
          description = "current status of the scale. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status. Read-only.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v1.ScaleStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.ScaleSpec" = {

      options = {
        "replicas" = mkOption {
          description = "desired number of instances for the scaled object.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "replicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v1.ScaleStatus" = {

      options = {
        "replicas" = mkOption {
          description = "actual number of observed instances of the scaled object.";
          type = types.int;
        };
        "selector" = mkOption {
          description = "label query over pods that should match the replicas count. This is same as the label selector but in the string format to avoid introspection by clients. The string will be in the same format as the query-param syntax. More info about label selectors: http://kubernetes.io/docs/user-guide/labels#label-selectors";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "selector" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.ContainerResourceMetricSource" = {

      options = {
        "container" = mkOption {
          description = "container is the name of the container in the pods of the scaling target";
          type = types.str;
        };
        "name" = mkOption {
          description = "name is the name of the resource in question.";
          type = types.str;
        };
        "target" = mkOption {
          description = "target specifies the target value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricTarget");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.ContainerResourceMetricStatus" = {

      options = {
        "container" = mkOption {
          description = "Container is the name of the container in the pods of the scaling target";
          type = types.str;
        };
        "current" = mkOption {
          description = "current contains the current value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricValueStatus");
        };
        "name" = mkOption {
          description = "Name is the name of the resource in question.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.CrossVersionObjectReference" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of the referent; More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent; More info: http://kubernetes.io/docs/user-guide/identifiers#names";
          type = types.str;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.ExternalMetricSource" = {

      options = {
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
        "target" = mkOption {
          description = "target specifies the target value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricTarget");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.ExternalMetricStatus" = {

      options = {
        "current" = mkOption {
          description = "current contains the current value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricValueStatus");
        };
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.HPAScalingPolicy" = {

      options = {
        "periodSeconds" = mkOption {
          description = "PeriodSeconds specifies the window of time for which the policy should hold true. PeriodSeconds must be greater than zero and less than or equal to 1800 (30 min).";
          type = types.int;
        };
        "type" = mkOption {
          description = "Type is used to specify the scaling policy.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value contains the amount of change which is permitted by the policy. It must be greater than zero";
          type = types.int;
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.HPAScalingRules" = {

      options = {
        "policies" = mkOption {
          description = "policies is a list of potential scaling polices which can be used during scaling. At least one policy must be specified, otherwise the HPAScalingRules will be discarded as invalid";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.autoscaling.v2.HPAScalingPolicy")));
        };
        "selectPolicy" = mkOption {
          description = "selectPolicy is used to specify which policy should be used. If not set, the default value Max is used.";
          type = (types.nullOr types.str);
        };
        "stabilizationWindowSeconds" = mkOption {
          description = "StabilizationWindowSeconds is the number of seconds for which past recommendations should be considered while scaling up or scaling down. StabilizationWindowSeconds must be greater than or equal to zero and less than or equal to 3600 (one hour). If not set, use the default values: - For scale up: 0 (i.e. no stabilization is done). - For scale down: 300 (i.e. the stabilization window is 300 seconds long).";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "policies" = mkOverride 1002 null;
        "selectPolicy" = mkOverride 1002 null;
        "stabilizationWindowSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscaler" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "metadata is the standard object metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec is the specification for the behaviour of the autoscaler. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerSpec"));
        };
        "status" = mkOption {
          description = "status is the current information about the autoscaler.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerBehavior" = {

      options = {
        "scaleDown" = mkOption {
          description = "scaleDown is scaling policy for scaling Down. If not set, the default value is to allow to scale down to minReplicas pods, with a 300 second stabilization window (i.e., the highest recommendation for the last 300sec is used).";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.HPAScalingRules"));
        };
        "scaleUp" = mkOption {
          description = "scaleUp is scaling policy for scaling Up. If not set, the default value is the higher of:\n  * increase no more than 4 pods per 60 seconds\n  * double the number of pods per 60 seconds\nNo stabilization is used.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.HPAScalingRules"));
        };
      };


      config = {
        "scaleDown" = mkOverride 1002 null;
        "scaleUp" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "message is a human-readable explanation containing details about the transition";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is the reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "status is the status of the condition (True, False, Unknown)";
          type = types.str;
        };
        "type" = mkOption {
          description = "type describes the current condition";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of horizontal pod autoscaler objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.autoscaling.v2.HorizontalPodAutoscaler"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "metadata is the standard list metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerSpec" = {

      options = {
        "behavior" = mkOption {
          description = "behavior configures the scaling behavior of the target in both Up and Down directions (scaleUp and scaleDown fields respectively). If not set, the default HPAScalingRules for scale up and scale down are used.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerBehavior"));
        };
        "maxReplicas" = mkOption {
          description = "maxReplicas is the upper limit for the number of replicas to which the autoscaler can scale up. It cannot be less that minReplicas.";
          type = types.int;
        };
        "metrics" = mkOption {
          description = "metrics contains the specifications for which to use to calculate the desired replica count (the maximum replica count across all metrics will be used).  The desired replica count is calculated multiplying the ratio between the target value and the current value by the current number of pods.  Ergo, metrics used must decrease as the pod count is increased, and vice-versa.  See the individual metric source types for more information about how each type of metric must respond. If not set, the default metric will be set to 80% average CPU utilization.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.autoscaling.v2.MetricSpec")));
        };
        "minReplicas" = mkOption {
          description = "minReplicas is the lower limit for the number of replicas to which the autoscaler can scale down.  It defaults to 1 pod.  minReplicas is allowed to be 0 if the alpha feature gate HPAScaleToZero is enabled and at least one Object or External metric is configured.  Scaling is active as long as at least one metric value is available.";
          type = (types.nullOr types.int);
        };
        "scaleTargetRef" = mkOption {
          description = "scaleTargetRef points to the target resource to scale, and is used to the pods for which metrics should be collected, as well as to actually change the replica count.";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.CrossVersionObjectReference");
        };
      };


      config = {
        "behavior" = mkOverride 1002 null;
        "metrics" = mkOverride 1002 null;
        "minReplicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerStatus" = {

      options = {
        "conditions" = mkOption {
          description = "conditions is the set of conditions required for this autoscaler to scale its target, and indicates whether or not those conditions are met.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerCondition" "type"));
          apply = attrsToList;
        };
        "currentMetrics" = mkOption {
          description = "currentMetrics is the last read state of the metrics used by this autoscaler.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.autoscaling.v2.MetricStatus")));
        };
        "currentReplicas" = mkOption {
          description = "currentReplicas is current number of replicas of pods managed by this autoscaler, as last seen by the autoscaler.";
          type = (types.nullOr types.int);
        };
        "desiredReplicas" = mkOption {
          description = "desiredReplicas is the desired number of replicas of pods managed by this autoscaler, as last calculated by the autoscaler.";
          type = types.int;
        };
        "lastScaleTime" = mkOption {
          description = "lastScaleTime is the last time the HorizontalPodAutoscaler scaled the number of pods, used by the autoscaler to control how often the number of pods is changed.";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration is the most recent generation observed by this autoscaler.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "currentMetrics" = mkOverride 1002 null;
        "currentReplicas" = mkOverride 1002 null;
        "lastScaleTime" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.MetricIdentifier" = {

      options = {
        "name" = mkOption {
          description = "name is the name of the given metric";
          type = types.str;
        };
        "selector" = mkOption {
          description = "selector is the string-encoded form of a standard kubernetes label selector for the given metric When set, it is passed as an additional parameter to the metrics server for more specific metrics scoping. When unset, just the metricName will be used to gather metrics.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
      };


      config = {
        "selector" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.MetricSpec" = {

      options = {
        "containerResource" = mkOption {
          description = "containerResource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing a single container in each pod of the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the \"pods\" source. This is an alpha feature and can be enabled by the HPAContainerMetrics feature flag.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ContainerResourceMetricSource"));
        };
        "external" = mkOption {
          description = "external refers to a global metric that is not associated with any Kubernetes object. It allows autoscaling based on information coming from components running outside of cluster (for example length of queue in cloud messaging service, or QPS from loadbalancer running outside of cluster).";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ExternalMetricSource"));
        };
        "object" = mkOption {
          description = "object refers to a metric describing a single kubernetes object (for example, hits-per-second on an Ingress object).";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ObjectMetricSource"));
        };
        "pods" = mkOption {
          description = "pods refers to a metric describing each pod in the current scale target (for example, transactions-processed-per-second).  The values will be averaged together before being compared to the target value.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.PodsMetricSource"));
        };
        "resource" = mkOption {
          description = "resource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing each pod in the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the \"pods\" source.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ResourceMetricSource"));
        };
        "type" = mkOption {
          description = "type is the type of metric source.  It should be one of \"ContainerResource\", \"External\", \"Object\", \"Pods\" or \"Resource\", each mapping to a matching field in the object. Note: \"ContainerResource\" type is available on when the feature-gate HPAContainerMetrics is enabled";
          type = types.str;
        };
      };


      config = {
        "containerResource" = mkOverride 1002 null;
        "external" = mkOverride 1002 null;
        "object" = mkOverride 1002 null;
        "pods" = mkOverride 1002 null;
        "resource" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.MetricStatus" = {

      options = {
        "containerResource" = mkOption {
          description = "container resource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing a single container in each pod in the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the \"pods\" source.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ContainerResourceMetricStatus"));
        };
        "external" = mkOption {
          description = "external refers to a global metric that is not associated with any Kubernetes object. It allows autoscaling based on information coming from components running outside of cluster (for example length of queue in cloud messaging service, or QPS from loadbalancer running outside of cluster).";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ExternalMetricStatus"));
        };
        "object" = mkOption {
          description = "object refers to a metric describing a single kubernetes object (for example, hits-per-second on an Ingress object).";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ObjectMetricStatus"));
        };
        "pods" = mkOption {
          description = "pods refers to a metric describing each pod in the current scale target (for example, transactions-processed-per-second).  The values will be averaged together before being compared to the target value.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.PodsMetricStatus"));
        };
        "resource" = mkOption {
          description = "resource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing each pod in the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the \"pods\" source.";
          type = (types.nullOr (submoduleOf "io.k8s.api.autoscaling.v2.ResourceMetricStatus"));
        };
        "type" = mkOption {
          description = "type is the type of metric source.  It will be one of \"ContainerResource\", \"External\", \"Object\", \"Pods\" or \"Resource\", each corresponds to a matching field in the object. Note: \"ContainerResource\" type is available on when the feature-gate HPAContainerMetrics is enabled";
          type = types.str;
        };
      };


      config = {
        "containerResource" = mkOverride 1002 null;
        "external" = mkOverride 1002 null;
        "object" = mkOverride 1002 null;
        "pods" = mkOverride 1002 null;
        "resource" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.MetricTarget" = {

      options = {
        "averageUtilization" = mkOption {
          description = "averageUtilization is the target value of the average of the resource metric across all relevant pods, represented as a percentage of the requested value of the resource for the pods. Currently only valid for Resource metric source type";
          type = (types.nullOr types.int);
        };
        "averageValue" = mkOption {
          description = "averageValue is the target value of the average of the metric across all relevant pods (as a quantity)";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type represents whether the metric type is Utilization, Value, or AverageValue";
          type = types.str;
        };
        "value" = mkOption {
          description = "value is the target value of the metric (as a quantity).";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "averageUtilization" = mkOverride 1002 null;
        "averageValue" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.MetricValueStatus" = {

      options = {
        "averageUtilization" = mkOption {
          description = "currentAverageUtilization is the current value of the average of the resource metric across all relevant pods, represented as a percentage of the requested value of the resource for the pods.";
          type = (types.nullOr types.int);
        };
        "averageValue" = mkOption {
          description = "averageValue is the current value of the average of the metric across all relevant pods (as a quantity)";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "value is the current value of the metric (as a quantity).";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "averageUtilization" = mkOverride 1002 null;
        "averageValue" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.autoscaling.v2.ObjectMetricSource" = {

      options = {
        "describedObject" = mkOption {
          description = "describedObject specifies the descriptions of a object,such as kind,name apiVersion";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.CrossVersionObjectReference");
        };
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
        "target" = mkOption {
          description = "target specifies the target value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricTarget");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.ObjectMetricStatus" = {

      options = {
        "current" = mkOption {
          description = "current contains the current value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricValueStatus");
        };
        "describedObject" = mkOption {
          description = "DescribedObject specifies the descriptions of a object,such as kind,name apiVersion";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.CrossVersionObjectReference");
        };
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.PodsMetricSource" = {

      options = {
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
        "target" = mkOption {
          description = "target specifies the target value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricTarget");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.PodsMetricStatus" = {

      options = {
        "current" = mkOption {
          description = "current contains the current value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricValueStatus");
        };
        "metric" = mkOption {
          description = "metric identifies the target metric by name and selector";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricIdentifier");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.ResourceMetricSource" = {

      options = {
        "name" = mkOption {
          description = "name is the name of the resource in question.";
          type = types.str;
        };
        "target" = mkOption {
          description = "target specifies the target value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricTarget");
        };
      };


      config = { };

    };
    "io.k8s.api.autoscaling.v2.ResourceMetricStatus" = {

      options = {
        "current" = mkOption {
          description = "current contains the current value for the given metric";
          type = (submoduleOf "io.k8s.api.autoscaling.v2.MetricValueStatus");
        };
        "name" = mkOption {
          description = "Name is the name of the resource in question.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.batch.v1.CronJob" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of a cron job, including the schedule. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.CronJobSpec"));
        };
        "status" = mkOption {
          description = "Current status of a cron job. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.CronJobStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.CronJobList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of CronJobs.";
          type = (types.listOf (submoduleOf "io.k8s.api.batch.v1.CronJob"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.CronJobSpec" = {

      options = {
        "concurrencyPolicy" = mkOption {
          description = "Specifies how to treat concurrent executions of a Job. Valid values are: - \"Allow\" (default): allows CronJobs to run concurrently; - \"Forbid\": forbids concurrent runs, skipping next run if previous run hasn't finished yet; - \"Replace\": cancels currently running job and replaces it with a new one\n\n";
          type = (types.nullOr types.str);
        };
        "failedJobsHistoryLimit" = mkOption {
          description = "The number of failed finished jobs to retain. Value must be non-negative integer. Defaults to 1.";
          type = (types.nullOr types.int);
        };
        "jobTemplate" = mkOption {
          description = "Specifies the job that will be created when executing a CronJob.";
          type = (submoduleOf "io.k8s.api.batch.v1.JobTemplateSpec");
        };
        "schedule" = mkOption {
          description = "The schedule in Cron format, see https://en.wikipedia.org/wiki/Cron.";
          type = types.str;
        };
        "startingDeadlineSeconds" = mkOption {
          description = "Optional deadline in seconds for starting the job if it misses scheduled time for any reason.  Missed jobs executions will be counted as failed ones.";
          type = (types.nullOr types.int);
        };
        "successfulJobsHistoryLimit" = mkOption {
          description = "The number of successful finished jobs to retain. Value must be non-negative integer. Defaults to 3.";
          type = (types.nullOr types.int);
        };
        "suspend" = mkOption {
          description = "This flag tells the controller to suspend subsequent executions, it does not apply to already started executions.  Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "timeZone" = mkOption {
          description = "The time zone name for the given schedule, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones. If not specified, this will default to the time zone of the kube-controller-manager process. The set of valid time zone names and the time zone offset is loaded from the system-wide time zone database by the API server during CronJob validation and the controller manager during execution. If no system-wide time zone database can be found a bundled version of the database is used instead. If the time zone name becomes invalid during the lifetime of a CronJob or due to a change in host configuration, the controller will stop creating new new Jobs and will create a system event with the reason UnknownTimeZone. More information can be found in https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones This is beta field and must be enabled via the `CronJobTimeZone` feature gate.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "concurrencyPolicy" = mkOverride 1002 null;
        "failedJobsHistoryLimit" = mkOverride 1002 null;
        "startingDeadlineSeconds" = mkOverride 1002 null;
        "successfulJobsHistoryLimit" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "timeZone" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.CronJobStatus" = {

      options = {
        "active" = mkOption {
          description = "A list of pointers to currently running jobs.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ObjectReference")));
        };
        "lastScheduleTime" = mkOption {
          description = "Information when was the last time the job was successfully scheduled.";
          type = (types.nullOr types.str);
        };
        "lastSuccessfulTime" = mkOption {
          description = "Information when was the last time the job successfully completed.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "active" = mkOverride 1002 null;
        "lastScheduleTime" = mkOverride 1002 null;
        "lastSuccessfulTime" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.Job" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of a job. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.JobSpec"));
        };
        "status" = mkOption {
          description = "Current status of a job. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.JobStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.JobCondition" = {

      options = {
        "lastProbeTime" = mkOption {
          description = "Last time the condition was checked.";
          type = (types.nullOr types.str);
        };
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transit from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Human readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "(brief) reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of job condition, Complete or Failed.";
          type = types.str;
        };
      };


      config = {
        "lastProbeTime" = mkOverride 1002 null;
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.JobList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of Jobs.";
          type = (types.listOf (submoduleOf "io.k8s.api.batch.v1.Job"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.JobSpec" = {

      options = {
        "activeDeadlineSeconds" = mkOption {
          description = "Specifies the duration in seconds relative to the startTime that the job may be continuously active before the system tries to terminate it; value must be positive integer. If a Job is suspended (at creation or through an update), this timer will effectively be stopped and reset when the Job is resumed again.";
          type = (types.nullOr types.int);
        };
        "backoffLimit" = mkOption {
          description = "Specifies the number of retries before marking this job failed. Defaults to 6";
          type = (types.nullOr types.int);
        };
        "completionMode" = mkOption {
          description = "CompletionMode specifies how Pod completions are tracked. It can be `NonIndexed` (default) or `Indexed`.\n\n`NonIndexed` means that the Job is considered complete when there have been .spec.completions successfully completed Pods. Each Pod completion is homologous to each other.\n\n`Indexed` means that the Pods of a Job get an associated completion index from 0 to (.spec.completions - 1), available in the annotation batch.kubernetes.io/job-completion-index. The Job is considered complete when there is one successfully completed Pod for each index. When value is `Indexed`, .spec.completions must be specified and `.spec.parallelism` must be less than or equal to 10^5. In addition, The Pod name takes the form `$(job-name)-$(index)-$(random-string)`, the Pod hostname takes the form `$(job-name)-$(index)`.\n\nMore completion modes can be added in the future. If the Job controller observes a mode that it doesn't recognize, which is possible during upgrades due to version skew, the controller skips updates for the Job.";
          type = (types.nullOr types.str);
        };
        "completions" = mkOption {
          description = "Specifies the desired number of successfully finished pods the job should be run with.  Setting to nil means that the success of any pod signals the success of all pods, and allows parallelism to have any positive value.  Setting to 1 means that parallelism is limited to 1 and the success of that pod signals the success of the job. More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/";
          type = (types.nullOr types.int);
        };
        "manualSelector" = mkOption {
          description = "manualSelector controls generation of pod labels and pod selectors. Leave `manualSelector` unset unless you are certain what you are doing. When false or unset, the system pick labels unique to this job and appends those labels to the pod template.  When true, the user is responsible for picking unique labels and specifying the selector.  Failure to pick a unique label may cause this and other jobs to not function correctly.  However, You may see `manualSelector=true` in jobs that were created with the old `extensions/v1beta1` API. More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/#specifying-your-own-pod-selector";
          type = (types.nullOr types.bool);
        };
        "parallelism" = mkOption {
          description = "Specifies the maximum desired number of pods the job should run at any given time. The actual number of pods running in steady state will be less than this number when ((.spec.completions - .status.successful) < .spec.parallelism), i.e. when the work left to do is less than max parallelism. More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/";
          type = (types.nullOr types.int);
        };
        "podFailurePolicy" = mkOption {
          description = "Specifies the policy of handling failed pods. In particular, it allows to specify the set of actions and conditions which need to be satisfied to take the associated action. If empty, the default behaviour applies - the counter of failed pods, represented by the jobs's .status.failed field, is incremented and it is checked against the backoffLimit. This field cannot be used in combination with restartPolicy=OnFailure.\n\nThis field is alpha-level. To use this field, you must enable the `JobPodFailurePolicy` feature gate (disabled by default).";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.PodFailurePolicy"));
        };
        "selector" = mkOption {
          description = "A label query over pods that should match the pod count. Normally, the system sets this field for you. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "suspend" = mkOption {
          description = "Suspend specifies whether the Job controller should create Pods or not. If a Job is created with suspend set to true, no Pods are created by the Job controller. If a Job is suspended after creation (i.e. the flag goes from false to true), the Job controller will delete all active Pods associated with this Job. Users must design their workload to gracefully handle this. Suspending a Job will reset the StartTime field of the Job, effectively resetting the ActiveDeadlineSeconds timer too. Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "template" = mkOption {
          description = "Describes the pod that will be created when executing a job. More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/";
          type = (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec");
        };
        "ttlSecondsAfterFinished" = mkOption {
          description = "ttlSecondsAfterFinished limits the lifetime of a Job that has finished execution (either Complete or Failed). If this field is set, ttlSecondsAfterFinished after the Job finishes, it is eligible to be automatically deleted. When the Job is being deleted, its lifecycle guarantees (e.g. finalizers) will be honored. If this field is unset, the Job won't be automatically deleted. If this field is set to zero, the Job becomes eligible to be deleted immediately after it finishes.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "activeDeadlineSeconds" = mkOverride 1002 null;
        "backoffLimit" = mkOverride 1002 null;
        "completionMode" = mkOverride 1002 null;
        "completions" = mkOverride 1002 null;
        "manualSelector" = mkOverride 1002 null;
        "parallelism" = mkOverride 1002 null;
        "podFailurePolicy" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "ttlSecondsAfterFinished" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.JobStatus" = {

      options = {
        "active" = mkOption {
          description = "The number of pending and running pods.";
          type = (types.nullOr types.int);
        };
        "completedIndexes" = mkOption {
          description = "CompletedIndexes holds the completed indexes when .spec.completionMode = \"Indexed\" in a text format. The indexes are represented as decimal integers separated by commas. The numbers are listed in increasing order. Three or more consecutive numbers are compressed and represented by the first and last element of the series, separated by a hyphen. For example, if the completed indexes are 1, 3, 4, 5 and 7, they are represented as \"1,3-5,7\".";
          type = (types.nullOr types.str);
        };
        "completionTime" = mkOption {
          description = "Represents time when the job was completed. It is not guaranteed to be set in happens-before order across separate operations. It is represented in RFC3339 form and is in UTC. The completion time is only set when the job finishes successfully.";
          type = (types.nullOr types.str);
        };
        "conditions" = mkOption {
          description = "The latest available observations of an object's current state. When a Job fails, one of the conditions will have type \"Failed\" and status true. When a Job is suspended, one of the conditions will have type \"Suspended\" and status true; when the Job is resumed, the status of this condition will become false. When a Job is completed, one of the conditions will have type \"Complete\" and status true. More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.batch.v1.JobCondition" "type"));
          apply = attrsToList;
        };
        "failed" = mkOption {
          description = "The number of pods which reached phase Failed.";
          type = (types.nullOr types.int);
        };
        "ready" = mkOption {
          description = "The number of pods which have a Ready condition.\n\nThis field is beta-level. The job controller populates the field when the feature gate JobReadyPods is enabled (enabled by default).";
          type = (types.nullOr types.int);
        };
        "startTime" = mkOption {
          description = "Represents time when the job controller started processing a job. When a Job is created in the suspended state, this field is not set until the first time it is resumed. This field is reset every time a Job is resumed from suspension. It is represented in RFC3339 form and is in UTC.";
          type = (types.nullOr types.str);
        };
        "succeeded" = mkOption {
          description = "The number of pods which reached phase Succeeded.";
          type = (types.nullOr types.int);
        };
        "uncountedTerminatedPods" = mkOption {
          description = "UncountedTerminatedPods holds the UIDs of Pods that have terminated but the job controller hasn't yet accounted for in the status counters.\n\nThe job controller creates pods with a finalizer. When a pod terminates (succeeded or failed), the controller does three steps to account for it in the job status: (1) Add the pod UID to the arrays in this field. (2) Remove the pod finalizer. (3) Remove the pod UID from the arrays while increasing the corresponding\n    counter.\n\nOld jobs might not be tracked using this field, in which case the field remains null.";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.UncountedTerminatedPods"));
        };
      };


      config = {
        "active" = mkOverride 1002 null;
        "completedIndexes" = mkOverride 1002 null;
        "completionTime" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "failed" = mkOverride 1002 null;
        "ready" = mkOverride 1002 null;
        "startTime" = mkOverride 1002 null;
        "succeeded" = mkOverride 1002 null;
        "uncountedTerminatedPods" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.JobTemplateSpec" = {

      options = {
        "metadata" = mkOption {
          description = "Standard object's metadata of the jobs created from this template. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the job. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.JobSpec"));
        };
      };


      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.PodFailurePolicy" = {

      options = {
        "rules" = mkOption {
          description = "A list of pod failure policy rules. The rules are evaluated in order. Once a rule matches a Pod failure, the remaining of the rules are ignored. When no rule matches the Pod failure, the default handling applies - the counter of pod failures is incremented and it is checked against the backoffLimit. At most 20 elements are allowed.";
          type = (types.listOf (submoduleOf "io.k8s.api.batch.v1.PodFailurePolicyRule"));
        };
      };


      config = { };

    };
    "io.k8s.api.batch.v1.PodFailurePolicyOnExitCodesRequirement" = {

      options = {
        "containerName" = mkOption {
          description = "Restricts the check for exit codes to the container with the specified name. When null, the rule applies to all containers. When specified, it should match one the container or initContainer names in the pod template.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Represents the relationship between the container exit code(s) and the specified values. Containers completed with success (exit code 0) are excluded from the requirement check. Possible values are: - In: the requirement is satisfied if at least one container exit code\n  (might be multiple if there are multiple containers not restricted\n  by the 'containerName' field) is in the set of specified values.\n- NotIn: the requirement is satisfied if at least one container exit code\n  (might be multiple if there are multiple containers not restricted\n  by the 'containerName' field) is not in the set of specified values.\nAdditional values are considered to be added in the future. Clients should react to an unknown operator by assuming the requirement is not satisfied.\n\n";
          type = types.str;
        };
        "values" = mkOption {
          description = "Specifies the set of values. Each returned container exit code (might be multiple in case of multiple containers) is checked against this set of values with respect to the operator. The list of values must be ordered and must not contain duplicates. Value '0' cannot be used for the In operator. At least one element is required. At most 255 elements are allowed.";
          type = (types.listOf types.int);
        };
      };


      config = {
        "containerName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.PodFailurePolicyOnPodConditionsPattern" = {

      options = {
        "status" = mkOption {
          description = "Specifies the required Pod condition status. To match a pod condition it is required that the specified status equals the pod condition status. Defaults to True.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Specifies the required Pod condition type. To match a pod condition it is required that specified type equals the pod condition type.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.batch.v1.PodFailurePolicyRule" = {

      options = {
        "action" = mkOption {
          description = "Specifies the action taken on a pod failure when the requirements are satisfied. Possible values are: - FailJob: indicates that the pod's job is marked as Failed and all\n  running pods are terminated.\n- Ignore: indicates that the counter towards the .backoffLimit is not\n  incremented and a replacement pod is created.\n- Count: indicates that the pod is handled in the default way - the\n  counter towards the .backoffLimit is incremented.\nAdditional values are considered to be added in the future. Clients should react to an unknown action by skipping the rule.\n\n";
          type = types.str;
        };
        "onExitCodes" = mkOption {
          description = "Represents the requirement on the container exit codes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.batch.v1.PodFailurePolicyOnExitCodesRequirement"));
        };
        "onPodConditions" = mkOption {
          description = "Represents the requirement on the pod conditions. The requirement is represented as a list of pod condition patterns. The requirement is satisfied if at least one pattern matches an actual pod condition. At most 20 elements are allowed.";
          type = (types.listOf (submoduleOf "io.k8s.api.batch.v1.PodFailurePolicyOnPodConditionsPattern"));
        };
      };


      config = {
        "onExitCodes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.batch.v1.UncountedTerminatedPods" = {

      options = {
        "failed" = mkOption {
          description = "Failed holds UIDs of failed Pods.";
          type = (types.nullOr (types.listOf types.str));
        };
        "succeeded" = mkOption {
          description = "Succeeded holds UIDs of succeeded Pods.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "failed" = mkOverride 1002 null;
        "succeeded" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.certificates.v1.CertificateSigningRequest" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec contains the certificate request, and is immutable after creation. Only the request, signerName, expirationSeconds, and usages fields can be set on creation. Other fields are derived by Kubernetes and cannot be modified by users.";
          type = (submoduleOf "io.k8s.api.certificates.v1.CertificateSigningRequestSpec");
        };
        "status" = mkOption {
          description = "status contains information about whether the request is approved or denied, and the certificate issued by the signer, or the failure condition indicating signer failure.";
          type = (types.nullOr (submoduleOf "io.k8s.api.certificates.v1.CertificateSigningRequestStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.certificates.v1.CertificateSigningRequestCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the time the condition last transitioned from one status to another. If unset, when a new condition type is added or an existing condition's status is changed, the server defaults this to the current time.";
          type = (types.nullOr types.str);
        };
        "lastUpdateTime" = mkOption {
          description = "lastUpdateTime is the time of the last update to this condition";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "message contains a human readable message with details about the request state";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason indicates a brief reason for the request state";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown. Approved, Denied, and Failed conditions may not be \"False\" or \"Unknown\".";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of the condition. Known conditions are \"Approved\", \"Denied\", and \"Failed\".\n\nAn \"Approved\" condition is added via the /approval subresource, indicating the request was approved and should be issued by the signer.\n\nA \"Denied\" condition is added via the /approval subresource, indicating the request was denied and should not be issued by the signer.\n\nA \"Failed\" condition is added via the /status subresource, indicating the signer failed to issue the certificate.\n\nApproved and Denied conditions are mutually exclusive. Approved, Denied, and Failed conditions cannot be removed once added.\n\nOnly one condition of a given type is allowed.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "lastUpdateTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.certificates.v1.CertificateSigningRequestList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is a collection of CertificateSigningRequest objects";
          type = (types.listOf (submoduleOf "io.k8s.api.certificates.v1.CertificateSigningRequest"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.certificates.v1.CertificateSigningRequestSpec" = {

      options = {
        "expirationSeconds" = mkOption {
          description = "expirationSeconds is the requested duration of validity of the issued certificate. The certificate signer may issue a certificate with a different validity duration so a client must check the delta between the notBefore and and notAfter fields in the issued certificate to determine the actual duration.\n\nThe v1.22+ in-tree implementations of the well-known Kubernetes signers will honor this field as long as the requested duration is not greater than the maximum duration they will honor per the --cluster-signing-duration CLI flag to the Kubernetes controller manager.\n\nCertificate signers may not honor this field for various reasons:\n\n  1. Old signer that is unaware of the field (such as the in-tree\n     implementations prior to v1.22)\n  2. Signer whose configured maximum is shorter than the requested duration\n  3. Signer whose configured minimum is longer than the requested duration\n\nThe minimum valid value for expirationSeconds is 600, i.e. 10 minutes.";
          type = (types.nullOr types.int);
        };
        "extra" = mkOption {
          description = "extra contains extra attributes of the user that created the CertificateSigningRequest. Populated by the API server on creation and immutable.";
          type = (types.nullOr (types.loaOf types.str));
        };
        "groups" = mkOption {
          description = "groups contains group membership of the user that created the CertificateSigningRequest. Populated by the API server on creation and immutable.";
          type = (types.nullOr (types.listOf types.str));
        };
        "request" = mkOption {
          description = "request contains an x509 certificate signing request encoded in a \"CERTIFICATE REQUEST\" PEM block. When serialized as JSON or YAML, the data is additionally base64-encoded.";
          type = types.str;
        };
        "signerName" = mkOption {
          description = "signerName indicates the requested signer, and is a qualified name.\n\nList/watch requests for CertificateSigningRequests can filter on this field using a \"spec.signerName=NAME\" fieldSelector.\n\nWell-known Kubernetes signers are:\n 1. \"kubernetes.io/kube-apiserver-client\": issues client certificates that can be used to authenticate to kube-apiserver.\n  Requests for this signer are never auto-approved by kube-controller-manager, can be issued by the \"csrsigning\" controller in kube-controller-manager.\n 2. \"kubernetes.io/kube-apiserver-client-kubelet\": issues client certificates that kubelets use to authenticate to kube-apiserver.\n  Requests for this signer can be auto-approved by the \"csrapproving\" controller in kube-controller-manager, and can be issued by the \"csrsigning\" controller in kube-controller-manager.\n 3. \"kubernetes.io/kubelet-serving\" issues serving certificates that kubelets use to serve TLS endpoints, which kube-apiserver can connect to securely.\n  Requests for this signer are never auto-approved by kube-controller-manager, and can be issued by the \"csrsigning\" controller in kube-controller-manager.\n\nMore details are available at https://k8s.io/docs/reference/access-authn-authz/certificate-signing-requests/#kubernetes-signers\n\nCustom signerNames can also be specified. The signer defines:\n 1. Trust distribution: how trust (CA bundles) are distributed.\n 2. Permitted subjects: and behavior when a disallowed subject is requested.\n 3. Required, permitted, or forbidden x509 extensions in the request (including whether subjectAltNames are allowed, which types, restrictions on allowed values) and behavior when a disallowed extension is requested.\n 4. Required, permitted, or forbidden key usages / extended key usages.\n 5. Expiration/certificate lifetime: whether it is fixed by the signer, configurable by the admin.\n 6. Whether or not requests for CA certificates are allowed.";
          type = types.str;
        };
        "uid" = mkOption {
          description = "uid contains the uid of the user that created the CertificateSigningRequest. Populated by the API server on creation and immutable.";
          type = (types.nullOr types.str);
        };
        "usages" = mkOption {
          description = "usages specifies a set of key usages requested in the issued certificate.\n\nRequests for TLS client certificates typically request: \"digital signature\", \"key encipherment\", \"client auth\".\n\nRequests for TLS serving certificates typically request: \"key encipherment\", \"digital signature\", \"server auth\".\n\nValid values are:\n \"signing\", \"digital signature\", \"content commitment\",\n \"key encipherment\", \"key agreement\", \"data encipherment\",\n \"cert sign\", \"crl sign\", \"encipher only\", \"decipher only\", \"any\",\n \"server auth\", \"client auth\",\n \"code signing\", \"email protection\", \"s/mime\",\n \"ipsec end system\", \"ipsec tunnel\", \"ipsec user\",\n \"timestamping\", \"ocsp signing\", \"microsoft sgc\", \"netscape sgc\"";
          type = (types.nullOr (types.listOf types.str));
        };
        "username" = mkOption {
          description = "username contains the name of the user that created the CertificateSigningRequest. Populated by the API server on creation and immutable.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "expirationSeconds" = mkOverride 1002 null;
        "extra" = mkOverride 1002 null;
        "groups" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "usages" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.certificates.v1.CertificateSigningRequestStatus" = {

      options = {
        "certificate" = mkOption {
          description = "certificate is populated with an issued certificate by the signer after an Approved condition is present. This field is set via the /status subresource. Once populated, this field is immutable.\n\nIf the certificate signing request is denied, a condition of type \"Denied\" is added and this field remains empty. If the signer cannot issue the certificate, a condition of type \"Failed\" is added and this field remains empty.\n\nValidation requirements:\n 1. certificate must contain one or more PEM blocks.\n 2. All PEM blocks must have the \"CERTIFICATE\" label, contain no headers, and the encoded data\n  must be a BER-encoded ASN.1 Certificate structure as described in section 4 of RFC5280.\n 3. Non-PEM content may appear before or after the \"CERTIFICATE\" PEM blocks and is unvalidated,\n  to allow for explanatory text as described in section 5.2 of RFC7468.\n\nIf more than one PEM block is present, and the definition of the requested spec.signerName does not indicate otherwise, the first block is the issued certificate, and subsequent blocks should be treated as intermediate certificates and presented in TLS handshakes.\n\nThe certificate is encoded in PEM format.\n\nWhen serialized as JSON or YAML, the data is additionally base64-encoded, so it consists of:\n\n    base64(\n    -----BEGIN CERTIFICATE-----\n    ...\n    -----END CERTIFICATE-----\n    )";
          type = (types.nullOr types.str);
        };
        "conditions" = mkOption {
          description = "conditions applied to the request. Known conditions are \"Approved\", \"Denied\", and \"Failed\".";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.certificates.v1.CertificateSigningRequestCondition")));
        };
      };


      config = {
        "certificate" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.coordination.v1.Lease" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the Lease. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.coordination.v1.LeaseSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.coordination.v1.LeaseList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of schema objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.coordination.v1.Lease"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.coordination.v1.LeaseSpec" = {

      options = {
        "acquireTime" = mkOption {
          description = "acquireTime is a time when the current lease was acquired.";
          type = (types.nullOr types.str);
        };
        "holderIdentity" = mkOption {
          description = "holderIdentity contains the identity of the holder of a current lease.";
          type = (types.nullOr types.str);
        };
        "leaseDurationSeconds" = mkOption {
          description = "leaseDurationSeconds is a duration that candidates for a lease need to wait to force acquire it. This is measure against time of last observed RenewTime.";
          type = (types.nullOr types.int);
        };
        "leaseTransitions" = mkOption {
          description = "leaseTransitions is the number of transitions of a lease between holders.";
          type = (types.nullOr types.int);
        };
        "renewTime" = mkOption {
          description = "renewTime is a time when the current holder of a lease has last updated the lease.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "acquireTime" = mkOverride 1002 null;
        "holderIdentity" = mkOverride 1002 null;
        "leaseDurationSeconds" = mkOverride 1002 null;
        "leaseTransitions" = mkOverride 1002 null;
        "renewTime" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.AWSElasticBlockStoreVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount. If omitted, the default is to mount by volume name. Examples: For volume /dev/sda1, you specify the partition as \"1\". Similarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty).";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly value true will force the readOnly setting in VolumeMounts. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID is unique ID of the persistent disk resource in AWS (Amazon EBS volume). More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Affinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeAffinity"));
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodAffinity"));
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodAntiAffinity"));
        };
      };


      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.AttachedVolume" = {

      options = {
        "devicePath" = mkOption {
          description = "DevicePath represents the device path where the volume should be available";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the attached volume";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.AzureDiskVolumeSource" = {

      options = {
        "cachingMode" = mkOption {
          description = "cachingMode is the Host Caching mode: None, Read Only, Read Write.";
          type = (types.nullOr types.str);
        };
        "diskName" = mkOption {
          description = "diskName is the Name of the data disk in the blob storage";
          type = types.str;
        };
        "diskURI" = mkOption {
          description = "diskURI is the URI of data disk in the blob storage";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is Filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "cachingMode" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.AzureFilePersistentVolumeSource" = {

      options = {
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the name of secret that contains Azure Storage Account Name and Key";
          type = types.str;
        };
        "secretNamespace" = mkOption {
          description = "secretNamespace is the namespace of the secret that contains Azure Storage Account Name and Key default is the same as the Pod";
          type = (types.nullOr types.str);
        };
        "shareName" = mkOption {
          description = "shareName is the azure Share Name";
          type = types.str;
        };
      };


      config = {
        "readOnly" = mkOverride 1002 null;
        "secretNamespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.AzureFileVolumeSource" = {

      options = {
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the  name of secret that contains Azure Storage Account Name and Key";
          type = types.str;
        };
        "shareName" = mkOption {
          description = "shareName is the azure share Name";
          type = types.str;
        };
      };


      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Binding" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "target" = mkOption {
          description = "The target object that you want to bind to the standard object.";
          type = (submoduleOf "io.k8s.api.core.v1.ObjectReference");
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CSIPersistentVolumeSource" = {

      options = {
        "controllerExpandSecretRef" = mkOption {
          description = "controllerExpandSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI ControllerExpandVolume call. This is an beta field and requires enabling ExpandCSIVolumes feature gate. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "controllerPublishSecretRef" = mkOption {
          description = "controllerPublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI ControllerPublishVolume and ControllerUnpublishVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "driver" = mkOption {
          description = "driver is the name of the driver to use for this volume. Required.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\".";
          type = (types.nullOr types.str);
        };
        "nodeExpandSecretRef" = mkOption {
          description = "nodeExpandSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodeExpandVolume call. This is an alpha field and requires enabling CSINodeExpandSecret feature gate. This field is optional, may be omitted if no secret is required. If the secret object contains more than one secret, all secrets are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "nodePublishSecretRef" = mkOption {
          description = "nodePublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodePublishVolume and NodeUnpublishVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "nodeStageSecretRef" = mkOption {
          description = "nodeStageSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodeStageVolume and NodeStageVolume and NodeUnstageVolume calls. This field is optional, and may be empty if no secret is required. If the secret object contains more than one secret, all secrets are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "readOnly" = mkOption {
          description = "readOnly value to pass to ControllerPublishVolumeRequest. Defaults to false (read/write).";
          type = (types.nullOr types.bool);
        };
        "volumeAttributes" = mkOption {
          description = "volumeAttributes of the volume to publish.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "volumeHandle" = mkOption {
          description = "volumeHandle is the unique volume name returned by the CSI volume plugin’s CreateVolume to refer to the volume on all subsequent calls. Required.";
          type = types.str;
        };
      };


      config = {
        "controllerExpandSecretRef" = mkOverride 1002 null;
        "controllerPublishSecretRef" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "nodeExpandSecretRef" = mkOverride 1002 null;
        "nodePublishSecretRef" = mkOverride 1002 null;
        "nodeStageSecretRef" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "volumeAttributes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CSIVolumeSource" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the CSI driver that handles this volume. Consult with your admin for the correct name as registered in the cluster.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType to mount. Ex. \"ext4\", \"xfs\", \"ntfs\". If not provided, the empty value is passed to the associated CSI driver which will determine the default filesystem to apply.";
          type = (types.nullOr types.str);
        };
        "nodePublishSecretRef" = mkOption {
          description = "nodePublishSecretRef is a reference to the secret object containing sensitive information to pass to the CSI driver to complete the CSI NodePublishVolume and NodeUnpublishVolume calls. This field is optional, and  may be empty if no secret is required. If the secret object contains more than one secret, all secret references are passed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "readOnly" = mkOption {
          description = "readOnly specifies a read-only configuration for the volume. Defaults to false (read/write).";
          type = (types.nullOr types.bool);
        };
        "volumeAttributes" = mkOption {
          description = "volumeAttributes stores driver-specific properties that are passed to the CSI driver. Consult your driver's documentation for supported values.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "nodePublishSecretRef" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "volumeAttributes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Capabilities" = {

      options = {
        "add" = mkOption {
          description = "Added capabilities";
          type = (types.nullOr (types.listOf types.str));
        };
        "drop" = mkOption {
          description = "Removed capabilities";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "add" = mkOverride 1002 null;
        "drop" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CephFSPersistentVolumeSource" = {

      options = {
        "monitors" = mkOption {
          description = "monitors is Required: Monitors is a collection of Ceph monitors More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "path" = mkOption {
          description = "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts. More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretFile" = mkOption {
          description = "secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty. More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "user" = mkOption {
          description = "user is Optional: User is the rados user name, default is admin More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "path" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretFile" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CephFSVolumeSource" = {

      options = {
        "monitors" = mkOption {
          description = "monitors is Required: Monitors is a collection of Ceph monitors More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "path" = mkOption {
          description = "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts. More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretFile" = mkOption {
          description = "secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty. More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "user" = mkOption {
          description = "user is optional: User is the rados user name, default is admin More info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "path" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretFile" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CinderPersistentVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType Filesystem type to mount. Must be a filesystem type supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: points to a secret object containing parameters used to connect to OpenStack.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "volumeID" = mkOption {
          description = "volumeID used to identify the volume in cinder. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.CinderVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is optional: points to a secret object containing parameters used to connect to OpenStack.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "volumeID" = mkOption {
          description = "volumeID used to identify the volume in cinder. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ClaimSource" = {

      options = {
        "resourceClaimName" = mkOption {
          description = "ResourceClaimName is the name of a ResourceClaim object in the same namespace as this pod.";
          type = (types.nullOr types.str);
        };
        "resourceClaimTemplateName" = mkOption {
          description = "ResourceClaimTemplateName is the name of a ResourceClaimTemplate object in the same namespace as this pod.\n\nThe template will be used to create a new ResourceClaim, which will be bound to this pod. When this pod is deleted, the ResourceClaim will also be deleted. The name of the ResourceClaim will be <pod name>-<resource name>, where <resource name> is the PodResourceClaim.Name. Pod validation will reject the pod if the concatenated name is not valid for a ResourceClaim (e.g. too long).\n\nAn existing ResourceClaim with that name that is not owned by the pod will not be used for the pod to avoid using an unrelated resource by mistake. Scheduling and pod startup are then blocked until the unrelated ResourceClaim is removed.\n\nThis field is immutable and no changes will be made to the corresponding ResourceClaim by the control plane after creating the ResourceClaim.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "resourceClaimName" = mkOverride 1002 null;
        "resourceClaimTemplateName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ClientIPConfig" = {

      options = {
        "timeoutSeconds" = mkOption {
          description = "timeoutSeconds specifies the seconds of ClientIP type session sticky time. The value must be >0 && <=86400(for 1 day) if ServiceAffinity == \"ClientIP\". Default value is 10800(for 3 hours).";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ComponentCondition" = {

      options = {
        "error" = mkOption {
          description = "Condition error code for a component. For example, a health check error code.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Message about the condition for a component. For example, information about a health check.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition for a component. Valid values for \"Healthy\": \"True\", \"False\", or \"Unknown\".";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of condition for a component. Valid value: \"Healthy\"";
          type = types.str;
        };
      };


      config = {
        "error" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ComponentStatus" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "conditions" = mkOption {
          description = "List of component conditions observed";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ComponentCondition" "type"));
          apply = attrsToList;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ComponentStatusList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of ComponentStatus objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.ComponentStatus"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMap" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "binaryData" = mkOption {
          description = "BinaryData contains the binary data. Each key must consist of alphanumeric characters, '-', '_' or '.'. BinaryData can contain byte sequences that are not in the UTF-8 range. The keys stored in BinaryData must not overlap with the ones in the Data field, this is enforced during validation process. Using this field will require 1.10+ apiserver and kubelet.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "data" = mkOption {
          description = "Data contains the configuration data. Each key must consist of alphanumeric characters, '-', '_' or '.'. Values with non-UTF-8 byte sequences must use the BinaryData field. The keys stored in Data must not overlap with the keys in the BinaryData field, this is enforced during validation process.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "immutable" = mkOption {
          description = "Immutable, if set to true, ensures that data stored in the ConfigMap cannot be updated (only object metadata can be modified). If not set to true, the field can be modified at any time. Defaulted to nil.";
          type = (types.nullOr types.bool);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "binaryData" = mkOverride 1002 null;
        "data" = mkOverride 1002 null;
        "immutable" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapEnvSource" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapKeySelector" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of ConfigMaps.";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.ConfigMap"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapNodeConfigSource" = {

      options = {
        "kubeletConfigKey" = mkOption {
          description = "KubeletConfigKey declares which key of the referenced ConfigMap corresponds to the KubeletConfiguration structure This field is required in all cases.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the metadata.name of the referenced ConfigMap. This field is required in all cases.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the metadata.namespace of the referenced ConfigMap. This field is required in all cases.";
          type = types.str;
        };
        "resourceVersion" = mkOption {
          description = "ResourceVersion is the metadata.ResourceVersion of the referenced ConfigMap. This field is forbidden in Node.Spec, and required in Node.Status.";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "UID is the metadata.UID of the referenced ConfigMap. This field is forbidden in Node.Spec, and required in Node.Status.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "resourceVersion" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapProjection" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced ConfigMap will be projected into the volume as a file whose name is the key and content is the value. If specified, the listed keys will be projected into the specified paths, and unlisted keys will not be present. If a key is specified which is not present in the ConfigMap, the volume setup will error unless it is marked optional. Paths must be relative and may not contain the '..' path or start with '..'.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.KeyToPath")));
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ConfigMapVolumeSource" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is optional: mode bits used to set permissions on created files by default. Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. Defaults to 0644. Directories within the path are not affected by this setting. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced ConfigMap will be projected into the volume as a file whose name is the key and content is the value. If specified, the listed keys will be projected into the specified paths, and unlisted keys will not be present. If a key is specified which is not present in the ConfigMap, the volume setup will error unless it is marked optional. Paths must be relative and may not contain the '..' path or start with '..'.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.KeyToPath")));
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Container" = {

      options = {
        "args" = mkOption {
          description = "Arguments to the entrypoint. The container image's CMD is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. \"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell";
          type = (types.nullOr (types.listOf types.str));
        };
        "command" = mkOption {
          description = "Entrypoint array. Not executed within a shell. The container image's ENTRYPOINT is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. \"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "List of environment variables to set in the container. Cannot be updated.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.EnvVar" "name"));
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "List of sources to populate environment variables in the container. The keys defined within a source must be a C_IDENTIFIER. All invalid keys will be reported as an event when the container is starting. When a key exists in multiple sources, the value associated with the last source will take precedence. Values defined by an Env with a duplicate key will take precedence. Cannot be updated.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EnvFromSource")));
        };
        "image" = mkOption {
          description = "Container image name. More info: https://kubernetes.io/docs/concepts/containers/images This field is optional to allow higher level config management to default or override container images in workload controllers like Deployments and StatefulSets.";
          type = (types.nullOr types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "Image pull policy. One of Always, Never, IfNotPresent. Defaults to Always if :latest tag is specified, or IfNotPresent otherwise. Cannot be updated. More info: https://kubernetes.io/docs/concepts/containers/images#updating-images\n\n";
          type = (types.nullOr types.str);
        };
        "lifecycle" = mkOption {
          description = "Actions that the management system should take in response to container lifecycle events. Cannot be updated.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Lifecycle"));
        };
        "livenessProbe" = mkOption {
          description = "Periodic probe of container liveness. Container will be restarted if the probe fails. Cannot be updated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "name" = mkOption {
          description = "Name of the container specified as a DNS_LABEL. Each container in a pod must have a unique name (DNS_LABEL). Cannot be updated.";
          type = types.str;
        };
        "ports" = mkOption {
          description = "List of ports to expose from the container. Not specifying a port here DOES NOT prevent that port from being exposed. Any port which is listening on the default \"0.0.0.0\" address inside a container will be accessible from the network. Modifying this array with strategic merge patch may corrupt the data. For more information See https://github.com/kubernetes/kubernetes/issues/108255. Cannot be updated.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ContainerPort" "containerPort"));
          apply = attrsToList;
        };
        "readinessProbe" = mkOption {
          description = "Periodic probe of container service readiness. Container will be removed from service endpoints if the probe fails. Cannot be updated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "resources" = mkOption {
          description = "Compute Resources required by this container. Cannot be updated. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceRequirements"));
        };
        "securityContext" = mkOption {
          description = "SecurityContext defines the security options the container should be run with. If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext. More info: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecurityContext"));
        };
        "startupProbe" = mkOption {
          description = "StartupProbe indicates that the Pod has successfully initialized. If specified, no other probes are executed until this completes successfully. If this probe fails, the Pod will be restarted, just as if the livenessProbe failed. This can be used to provide different probe parameters at the beginning of a Pod's lifecycle, when it might take a long time to load data or warm a cache, than during steady-state operation. This cannot be updated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "stdin" = mkOption {
          description = "Whether this container should allocate a buffer for stdin in the container runtime. If this is not set, reads from stdin in the container will always result in EOF. Default is false.";
          type = (types.nullOr types.bool);
        };
        "stdinOnce" = mkOption {
          description = "Whether the container runtime should close the stdin channel after it has been opened by a single attach. When stdin is true the stdin stream will remain open across multiple attach sessions. If stdinOnce is set to true, stdin is opened on container start, is empty until the first client attaches to stdin, and then remains open and accepts data until the client disconnects, at which time stdin is closed and remains closed until the container is restarted. If this flag is false, a container processes that reads from stdin will never receive an EOF. Default is false";
          type = (types.nullOr types.bool);
        };
        "terminationMessagePath" = mkOption {
          description = "Optional: Path at which the file to which the container's termination message will be written is mounted into the container's filesystem. Message written is intended to be brief final status, such as an assertion failure message. Will be truncated by the node if greater than 4096 bytes. The total message length across all containers will be limited to 12kb. Defaults to /dev/termination-log. Cannot be updated.";
          type = (types.nullOr types.str);
        };
        "terminationMessagePolicy" = mkOption {
          description = "Indicate how the termination message should be populated. File will use the contents of terminationMessagePath to populate the container status message on both success and failure. FallbackToLogsOnError will use the last chunk of container log output if the termination message file is empty and the container exited with an error. The log output is limited to 2048 bytes or 80 lines, whichever is smaller. Defaults to File. Cannot be updated.\n\n";
          type = (types.nullOr types.str);
        };
        "tty" = mkOption {
          description = "Whether this container should allocate a TTY for itself, also requires 'stdin' to be true. Default is false.";
          type = (types.nullOr types.bool);
        };
        "volumeDevices" = mkOption {
          description = "volumeDevices is the list of block devices to be used by the container.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.VolumeDevice" "devicePath"));
          apply = attrsToList;
        };
        "volumeMounts" = mkOption {
          description = "Pod volumes to mount into the container's filesystem. Cannot be updated.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.VolumeMount" "mountPath"));
          apply = attrsToList;
        };
        "workingDir" = mkOption {
          description = "Container's working directory. If not specified, the container runtime's default will be used, which might be configured in the container image. Cannot be updated.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "args" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "lifecycle" = mkOverride 1002 null;
        "livenessProbe" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "readinessProbe" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "startupProbe" = mkOverride 1002 null;
        "stdin" = mkOverride 1002 null;
        "stdinOnce" = mkOverride 1002 null;
        "terminationMessagePath" = mkOverride 1002 null;
        "terminationMessagePolicy" = mkOverride 1002 null;
        "tty" = mkOverride 1002 null;
        "volumeDevices" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "workingDir" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerImage" = {

      options = {
        "names" = mkOption {
          description = "Names by which this image is known. e.g. [\"kubernetes.example/hyperkube:v1.0.7\", \"cloud-vendor.registry.example/cloud-vendor/hyperkube:v1.0.7\"]";
          type = (types.nullOr (types.listOf types.str));
        };
        "sizeBytes" = mkOption {
          description = "The size of the image in bytes.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "names" = mkOverride 1002 null;
        "sizeBytes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerPort" = {

      options = {
        "containerPort" = mkOption {
          description = "Number of port to expose on the pod's IP address. This must be a valid port number, 0 < x < 65536.";
          type = types.int;
        };
        "hostIP" = mkOption {
          description = "What host IP to bind the external port to.";
          type = (types.nullOr types.str);
        };
        "hostPort" = mkOption {
          description = "Number of port to expose on the host. If specified, this must be a valid port number, 0 < x < 65536. If HostNetwork is specified, this must match ContainerPort. Most containers do not need this.";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "If specified, this must be an IANA_SVC_NAME and unique within the pod. Each named port in a pod must have a unique name. Name for the port that can be referred to by services.";
          type = (types.nullOr types.str);
        };
        "protocol" = mkOption {
          description = "Protocol for port. Must be UDP, TCP, or SCTP. Defaults to \"TCP\".\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "hostIP" = mkOverride 1002 null;
        "hostPort" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerState" = {

      options = {
        "running" = mkOption {
          description = "Details about a running container";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ContainerStateRunning"));
        };
        "terminated" = mkOption {
          description = "Details about a terminated container";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ContainerStateTerminated"));
        };
        "waiting" = mkOption {
          description = "Details about a waiting container";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ContainerStateWaiting"));
        };
      };


      config = {
        "running" = mkOverride 1002 null;
        "terminated" = mkOverride 1002 null;
        "waiting" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerStateRunning" = {

      options = {
        "startedAt" = mkOption {
          description = "Time at which the container was last (re-)started";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "startedAt" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerStateTerminated" = {

      options = {
        "containerID" = mkOption {
          description = "Container's ID in the format '<type>://<container_id>'";
          type = (types.nullOr types.str);
        };
        "exitCode" = mkOption {
          description = "Exit status from the last termination of the container";
          type = types.int;
        };
        "finishedAt" = mkOption {
          description = "Time at which the container last terminated";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Message regarding the last termination of the container";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "(brief) reason from the last termination of the container";
          type = (types.nullOr types.str);
        };
        "signal" = mkOption {
          description = "Signal from the last termination of the container";
          type = (types.nullOr types.int);
        };
        "startedAt" = mkOption {
          description = "Time at which previous execution of the container started";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "containerID" = mkOverride 1002 null;
        "finishedAt" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "signal" = mkOverride 1002 null;
        "startedAt" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerStateWaiting" = {

      options = {
        "message" = mkOption {
          description = "Message regarding why the container is not yet running.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "(brief) reason the container is not yet running.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ContainerStatus" = {

      options = {
        "containerID" = mkOption {
          description = "Container's ID in the format '<type>://<container_id>'.";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "The image the container is running. More info: https://kubernetes.io/docs/concepts/containers/images.";
          type = types.str;
        };
        "imageID" = mkOption {
          description = "ImageID of the container's image.";
          type = types.str;
        };
        "lastState" = mkOption {
          description = "Details about the container's last termination condition.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ContainerState"));
        };
        "name" = mkOption {
          description = "This must be a DNS_LABEL. Each container in a pod must have a unique name. Cannot be updated.";
          type = types.str;
        };
        "ready" = mkOption {
          description = "Specifies whether the container has passed its readiness probe.";
          type = types.bool;
        };
        "restartCount" = mkOption {
          description = "The number of times the container has been restarted.";
          type = types.int;
        };
        "started" = mkOption {
          description = "Specifies whether the container has passed its startup probe. Initialized as false, becomes true after startupProbe is considered successful. Resets to false when the container is restarted, or if kubelet loses state temporarily. Is always true when no startupProbe is defined.";
          type = (types.nullOr types.bool);
        };
        "state" = mkOption {
          description = "Details about the container's current condition.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ContainerState"));
        };
      };


      config = {
        "containerID" = mkOverride 1002 null;
        "lastState" = mkOverride 1002 null;
        "started" = mkOverride 1002 null;
        "state" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.DaemonEndpoint" = {

      options = {
        "Port" = mkOption {
          description = "Port number of the given endpoint.";
          type = types.int;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.DownwardAPIProjection" = {

      options = {
        "items" = mkOption {
          description = "Items is a list of DownwardAPIVolume file";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.DownwardAPIVolumeFile")));
        };
      };


      config = {
        "items" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.DownwardAPIVolumeFile" = {

      options = {
        "fieldRef" = mkOption {
          description = "Required: Selects a field of the pod: only annotations, labels, name and namespace are supported.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectFieldSelector"));
        };
        "mode" = mkOption {
          description = "Optional: mode bits used to set permissions on this file, must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. If not specified, the volume defaultMode will be used. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'";
          type = types.str;
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests (limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceFieldSelector"));
        };
      };


      config = {
        "fieldRef" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.DownwardAPIVolumeSource" = {

      options = {
        "defaultMode" = mkOption {
          description = "Optional: mode bits to use on created files by default. Must be a Optional: mode bits used to set permissions on created files by default. Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. Defaults to 0644. Directories within the path are not affected by this setting. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "Items is a list of downward API volume file";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.DownwardAPIVolumeFile")));
        };
      };


      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EmptyDirVolumeSource" = {

      options = {
        "medium" = mkOption {
          description = "medium represents what type of storage medium should back this directory. The default is \"\" which means to use the node's default medium. Must be an empty string (default) or Memory. More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr types.str);
        };
        "sizeLimit" = mkOption {
          description = "sizeLimit is the total amount of local storage required for this EmptyDir volume. The size limit is also applicable for memory medium. The maximum usage on memory medium EmptyDir would be the minimum value between the SizeLimit specified here and the sum of memory limits of all containers in a pod. The default is nil which means that the limit is undefined. More info: http://kubernetes.io/docs/user-guide/volumes#emptydir";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "medium" = mkOverride 1002 null;
        "sizeLimit" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EndpointAddress" = {

      options = {
        "hostname" = mkOption {
          description = "The Hostname of this endpoint";
          type = (types.nullOr types.str);
        };
        "ip" = mkOption {
          description = "The IP of this endpoint. May not be loopback (127.0.0.0/8), link-local (169.254.0.0/16), or link-local multicast ((224.0.0.0/24). IPv6 is also accepted but not fully supported on all platforms. Also, certain kubernetes components, like kube-proxy, are not IPv6 ready.";
          type = types.str;
        };
        "nodeName" = mkOption {
          description = "Optional: Node hosting this endpoint. This can be used to determine endpoints local to a node.";
          type = (types.nullOr types.str);
        };
        "targetRef" = mkOption {
          description = "Reference to object providing the endpoint.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
      };


      config = {
        "hostname" = mkOverride 1002 null;
        "nodeName" = mkOverride 1002 null;
        "targetRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EndpointPort" = {

      options = {
        "appProtocol" = mkOption {
          description = "The application protocol for this port. This field follows standard Kubernetes label syntax. Un-prefixed names are reserved for IANA standard service names (as per RFC-6335 and https://www.iana.org/assignments/service-names). Non-standard protocols should use prefixed names such as mycompany.com/my-custom-protocol.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of this port.  This must match the 'name' field in the corresponding ServicePort. Must be a DNS_LABEL. Optional only if one port is defined.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "The port number of the endpoint.";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "The IP protocol for this port. Must be UDP, TCP, or SCTP. Default is TCP.\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "appProtocol" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EndpointSubset" = {

      options = {
        "addresses" = mkOption {
          description = "IP addresses which offer the related ports that are marked as ready. These endpoints should be considered safe for load balancers and clients to utilize.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EndpointAddress")));
        };
        "notReadyAddresses" = mkOption {
          description = "IP addresses which offer the related ports but are not currently marked as ready because they have not yet finished starting, have recently failed a readiness check, or have recently failed a liveness check.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EndpointAddress")));
        };
        "ports" = mkOption {
          description = "Port numbers available on the related IP addresses.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EndpointPort")));
        };
      };


      config = {
        "addresses" = mkOverride 1002 null;
        "notReadyAddresses" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Endpoints" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "subsets" = mkOption {
          description = "The set of all endpoints is the union of all subsets. Addresses are placed into subsets according to the IPs they share. A single address with multiple ports, some of which are ready and some of which are not (because they come from different containers) will result in the address being displayed in different subsets for the different ports. No address will appear in both Addresses and NotReadyAddresses in the same subset. Sets of addresses and ports that comprise a service.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EndpointSubset")));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "subsets" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EndpointsList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of endpoints.";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Endpoints"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EnvFromSource" = {

      options = {
        "configMapRef" = mkOption {
          description = "The ConfigMap to select from";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ConfigMapEnvSource"));
        };
        "prefix" = mkOption {
          description = "An optional identifier to prepend to each key in the ConfigMap. Must be a C_IDENTIFIER.";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "The Secret to select from";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretEnvSource"));
        };
      };


      config = {
        "configMapRef" = mkOverride 1002 null;
        "prefix" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EnvVar" = {

      options = {
        "name" = mkOption {
          description = "Name of the environment variable. Must be a C_IDENTIFIER.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Variable references $(VAR_NAME) are expanded using the previously defined environment variables in the container and any service environment variables. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. \"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\". Escaped references will never be expanded, regardless of whether the variable exists or not. Defaults to \"\".";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "Source for the environment variable's value. Cannot be used if value is not empty.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EnvVarSource"));
        };
      };


      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EnvVarSource" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ConfigMapKeySelector"));
        };
        "fieldRef" = mkOption {
          description = "Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`, spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectFieldSelector"));
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests (limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceFieldSelector"));
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a secret in the pod's namespace";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretKeySelector"));
        };
      };


      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "fieldRef" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EphemeralContainer" = {

      options = {
        "args" = mkOption {
          description = "Arguments to the entrypoint. The image's CMD is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. \"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell";
          type = (types.nullOr (types.listOf types.str));
        };
        "command" = mkOption {
          description = "Entrypoint array. Not executed within a shell. The image's ENTRYPOINT is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. \"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "List of environment variables to set in the container. Cannot be updated.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.EnvVar" "name"));
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "List of sources to populate environment variables in the container. The keys defined within a source must be a C_IDENTIFIER. All invalid keys will be reported as an event when the container is starting. When a key exists in multiple sources, the value associated with the last source will take precedence. Values defined by an Env with a duplicate key will take precedence. Cannot be updated.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.EnvFromSource")));
        };
        "image" = mkOption {
          description = "Container image name. More info: https://kubernetes.io/docs/concepts/containers/images";
          type = (types.nullOr types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "Image pull policy. One of Always, Never, IfNotPresent. Defaults to Always if :latest tag is specified, or IfNotPresent otherwise. Cannot be updated. More info: https://kubernetes.io/docs/concepts/containers/images#updating-images\n\n";
          type = (types.nullOr types.str);
        };
        "lifecycle" = mkOption {
          description = "Lifecycle is not allowed for ephemeral containers.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Lifecycle"));
        };
        "livenessProbe" = mkOption {
          description = "Probes are not allowed for ephemeral containers.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "name" = mkOption {
          description = "Name of the ephemeral container specified as a DNS_LABEL. This name must be unique among all containers, init containers and ephemeral containers.";
          type = types.str;
        };
        "ports" = mkOption {
          description = "Ports are not allowed for ephemeral containers.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ContainerPort" "containerPort"));
          apply = attrsToList;
        };
        "readinessProbe" = mkOption {
          description = "Probes are not allowed for ephemeral containers.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "resources" = mkOption {
          description = "Resources are not allowed for ephemeral containers. Ephemeral containers use spare resources already allocated to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceRequirements"));
        };
        "securityContext" = mkOption {
          description = "Optional: SecurityContext defines the security options the ephemeral container should be run with. If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecurityContext"));
        };
        "startupProbe" = mkOption {
          description = "Probes are not allowed for ephemeral containers.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Probe"));
        };
        "stdin" = mkOption {
          description = "Whether this container should allocate a buffer for stdin in the container runtime. If this is not set, reads from stdin in the container will always result in EOF. Default is false.";
          type = (types.nullOr types.bool);
        };
        "stdinOnce" = mkOption {
          description = "Whether the container runtime should close the stdin channel after it has been opened by a single attach. When stdin is true the stdin stream will remain open across multiple attach sessions. If stdinOnce is set to true, stdin is opened on container start, is empty until the first client attaches to stdin, and then remains open and accepts data until the client disconnects, at which time stdin is closed and remains closed until the container is restarted. If this flag is false, a container processes that reads from stdin will never receive an EOF. Default is false";
          type = (types.nullOr types.bool);
        };
        "targetContainerName" = mkOption {
          description = "If set, the name of the container from PodSpec that this ephemeral container targets. The ephemeral container will be run in the namespaces (IPC, PID, etc) of this container. If not set then the ephemeral container uses the namespaces configured in the Pod spec.\n\nThe container runtime must implement support for this feature. If the runtime does not support namespace targeting then the result of setting this field is undefined.";
          type = (types.nullOr types.str);
        };
        "terminationMessagePath" = mkOption {
          description = "Optional: Path at which the file to which the container's termination message will be written is mounted into the container's filesystem. Message written is intended to be brief final status, such as an assertion failure message. Will be truncated by the node if greater than 4096 bytes. The total message length across all containers will be limited to 12kb. Defaults to /dev/termination-log. Cannot be updated.";
          type = (types.nullOr types.str);
        };
        "terminationMessagePolicy" = mkOption {
          description = "Indicate how the termination message should be populated. File will use the contents of terminationMessagePath to populate the container status message on both success and failure. FallbackToLogsOnError will use the last chunk of container log output if the termination message file is empty and the container exited with an error. The log output is limited to 2048 bytes or 80 lines, whichever is smaller. Defaults to File. Cannot be updated.\n\n";
          type = (types.nullOr types.str);
        };
        "tty" = mkOption {
          description = "Whether this container should allocate a TTY for itself, also requires 'stdin' to be true. Default is false.";
          type = (types.nullOr types.bool);
        };
        "volumeDevices" = mkOption {
          description = "volumeDevices is the list of block devices to be used by the container.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.VolumeDevice" "devicePath"));
          apply = attrsToList;
        };
        "volumeMounts" = mkOption {
          description = "Pod volumes to mount into the container's filesystem. Subpath mounts are not allowed for ephemeral containers. Cannot be updated.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.VolumeMount" "mountPath"));
          apply = attrsToList;
        };
        "workingDir" = mkOption {
          description = "Container's working directory. If not specified, the container runtime's default will be used, which might be configured in the container image. Cannot be updated.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "args" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "lifecycle" = mkOverride 1002 null;
        "livenessProbe" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "readinessProbe" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "startupProbe" = mkOverride 1002 null;
        "stdin" = mkOverride 1002 null;
        "stdinOnce" = mkOverride 1002 null;
        "targetContainerName" = mkOverride 1002 null;
        "terminationMessagePath" = mkOverride 1002 null;
        "terminationMessagePolicy" = mkOverride 1002 null;
        "tty" = mkOverride 1002 null;
        "volumeDevices" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "workingDir" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EphemeralVolumeSource" = {

      options = {
        "volumeClaimTemplate" = mkOption {
          description = "Will be used to create a stand-alone PVC to provision the volume. The pod in which this EphemeralVolumeSource is embedded will be the owner of the PVC, i.e. the PVC will be deleted together with the pod.  The name of the PVC will be `<pod name>-<volume name>` where `<volume name>` is the name from the `PodSpec.Volumes` array entry. Pod validation will reject the pod if the concatenated name is not valid for a PVC (for example, too long).\n\nAn existing PVC with that name that is not owned by the pod will *not* be used for the pod to avoid using an unrelated volume by mistake. Starting the pod is then blocked until the unrelated PVC is removed. If such a pre-created PVC is meant to be used by the pod, the PVC has to updated with an owner reference to the pod once the pod exists. Normally this should not be necessary, but it may be useful when manually reconstructing a broken cluster.\n\nThis field is read-only and no changes will be made by Kubernetes to the PVC after it has been created.\n\nRequired, must not be nil.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaimTemplate"));
        };
      };


      config = {
        "volumeClaimTemplate" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Event" = {

      options = {
        "action" = mkOption {
          description = "What action was taken/failed regarding to the Regarding object.";
          type = (types.nullOr types.str);
        };
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "count" = mkOption {
          description = "The number of times this event has occurred.";
          type = (types.nullOr types.int);
        };
        "eventTime" = mkOption {
          description = "Time when this Event was first observed.";
          type = (types.nullOr types.str);
        };
        "firstTimestamp" = mkOption {
          description = "The time at which the event was first recorded. (Time of server receipt is in TypeMeta.)";
          type = (types.nullOr types.str);
        };
        "involvedObject" = mkOption {
          description = "The object that this event is about.";
          type = (submoduleOf "io.k8s.api.core.v1.ObjectReference");
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "lastTimestamp" = mkOption {
          description = "The time at which the most recent occurrence of this event was recorded.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable description of the status of this operation.";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta");
        };
        "reason" = mkOption {
          description = "This should be a short, machine understandable string that gives the reason for the transition into the object's current status.";
          type = (types.nullOr types.str);
        };
        "related" = mkOption {
          description = "Optional secondary object for more complex actions.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "reportingComponent" = mkOption {
          description = "Name of the controller that emitted this Event, e.g. `kubernetes.io/kubelet`.";
          type = (types.nullOr types.str);
        };
        "reportingInstance" = mkOption {
          description = "ID of the controller instance, e.g. `kubelet-xyzf`.";
          type = (types.nullOr types.str);
        };
        "series" = mkOption {
          description = "Data about the Event series this event represents or nil if it's a singleton Event.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EventSeries"));
        };
        "source" = mkOption {
          description = "The component reporting this event. Should be a short machine understandable string.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EventSource"));
        };
        "type" = mkOption {
          description = "Type of this event (Normal, Warning), new types could be added in the future";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "action" = mkOverride 1002 null;
        "apiVersion" = mkOverride 1002 null;
        "count" = mkOverride 1002 null;
        "eventTime" = mkOverride 1002 null;
        "firstTimestamp" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "lastTimestamp" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "related" = mkOverride 1002 null;
        "reportingComponent" = mkOverride 1002 null;
        "reportingInstance" = mkOverride 1002 null;
        "series" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EventList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of events";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Event"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EventSeries" = {

      options = {
        "count" = mkOption {
          description = "Number of occurrences in this series up to the last heartbeat time";
          type = (types.nullOr types.int);
        };
        "lastObservedTime" = mkOption {
          description = "Time of the last occurrence observed";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "count" = mkOverride 1002 null;
        "lastObservedTime" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.EventSource" = {

      options = {
        "component" = mkOption {
          description = "Component from which the event is generated.";
          type = (types.nullOr types.str);
        };
        "host" = mkOption {
          description = "Node name on which the event is generated.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "component" = mkOverride 1002 null;
        "host" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ExecAction" = {

      options = {
        "command" = mkOption {
          description = "Command is the command line to execute inside the container, the working directory for the command  is root ('/') in the container's filesystem. The command is simply exec'd, it is not run inside a shell, so traditional shell instructions ('|', etc) won't work. To use a shell, you need to explicitly call out to that shell. Exit status of 0 is treated as live/healthy and non-zero is unhealthy.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "command" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.FCVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun is Optional: FC target lun number";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "targetWWNs" = mkOption {
          description = "targetWWNs is Optional: FC target worldwide names (WWNs)";
          type = (types.nullOr (types.listOf types.str));
        };
        "wwids" = mkOption {
          description = "wwids Optional: FC volume world wide identifiers (wwids) Either wwids or combination of targetWWNs and lun must be set, but not both simultaneously.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "lun" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "targetWWNs" = mkOverride 1002 null;
        "wwids" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.FlexPersistentVolumeSource" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the driver to use for this volume.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is the Filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". The default filesystem depends on FlexVolume script.";
          type = (types.nullOr types.str);
        };
        "options" = mkOption {
          description = "options is Optional: this field holds extra command options if any.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: SecretRef is reference to the secret object containing sensitive information to pass to the plugin scripts. This may be empty if no secret object is specified. If the secret object contains more than one secret, all secrets are passed to the plugin scripts.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.FlexVolumeSource" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the driver to use for this volume.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". The default filesystem depends on FlexVolume script.";
          type = (types.nullOr types.str);
        };
        "options" = mkOption {
          description = "options is Optional: this field holds extra command options if any.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: secretRef is reference to the secret object containing sensitive information to pass to the plugin scripts. This may be empty if no secret object is specified. If the secret object contains more than one secret, all secrets are passed to the plugin scripts.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.FlockerVolumeSource" = {

      options = {
        "datasetName" = mkOption {
          description = "datasetName is Name of the dataset stored as metadata -> name on the dataset for Flocker should be considered as deprecated";
          type = (types.nullOr types.str);
        };
        "datasetUUID" = mkOption {
          description = "datasetUUID is the UUID of the dataset. This is unique identifier of a Flocker dataset";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "datasetName" = mkOverride 1002 null;
        "datasetUUID" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.GCEPersistentDiskVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount. If omitted, the default is to mount by volume name. Examples: For volume /dev/sda1, you specify the partition as \"1\". Similarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty). More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.int);
        };
        "pdName" = mkOption {
          description = "pdName is unique name of the PD resource in GCE. Used to identify the disk in GCE. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.GRPCAction" = {

      options = {
        "port" = mkOption {
          description = "Port number of the gRPC service. Number must be in the range 1 to 65535.";
          type = types.int;
        };
        "service" = mkOption {
          description = "Service is the name of the service to place in the gRPC HealthCheckRequest (see https://github.com/grpc/grpc/blob/master/doc/health-checking.md).\n\nIf this is not specified, the default behavior is defined by gRPC.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "service" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.GitRepoVolumeSource" = {

      options = {
        "directory" = mkOption {
          description = "directory is the target directory name. Must not contain or start with '..'.  If '.' is supplied, the volume directory will be the git repository.  Otherwise, if specified, the volume will contain the git repository in the subdirectory with the given name.";
          type = (types.nullOr types.str);
        };
        "repository" = mkOption {
          description = "repository is the URL";
          type = types.str;
        };
        "revision" = mkOption {
          description = "revision is the commit hash for the specified revision.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "directory" = mkOverride 1002 null;
        "revision" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.GlusterfsPersistentVolumeSource" = {

      options = {
        "endpoints" = mkOption {
          description = "endpoints is the endpoint name that details Glusterfs topology. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "endpointsNamespace" = mkOption {
          description = "endpointsNamespace is the namespace that contains Glusterfs endpoint. If this field is empty, the EndpointNamespace defaults to the same namespace as the bound PVC. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "path is the Glusterfs volume path. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Glusterfs volume to be mounted with read-only permissions. Defaults to false. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "endpointsNamespace" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.GlusterfsVolumeSource" = {

      options = {
        "endpoints" = mkOption {
          description = "endpoints is the endpoint name that details Glusterfs topology. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "path" = mkOption {
          description = "path is the Glusterfs volume path. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Glusterfs volume to be mounted with read-only permissions. Defaults to false. More info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.HTTPGetAction" = {

      options = {
        "host" = mkOption {
          description = "Host name to connect to, defaults to the pod IP. You probably want to set \"Host\" in httpHeaders instead.";
          type = (types.nullOr types.str);
        };
        "httpHeaders" = mkOption {
          description = "Custom headers to set in the request. HTTP allows repeated headers.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.HTTPHeader")));
        };
        "path" = mkOption {
          description = "Path to access on the HTTP server.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "Name or number of the port to access on the container. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.";
          type = (types.either types.int types.str);
        };
        "scheme" = mkOption {
          description = "Scheme to use for connecting to the host. Defaults to HTTP.\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "host" = mkOverride 1002 null;
        "httpHeaders" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.HTTPHeader" = {

      options = {
        "name" = mkOption {
          description = "The header field name";
          type = types.str;
        };
        "value" = mkOption {
          description = "The header field value";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.HostAlias" = {

      options = {
        "hostnames" = mkOption {
          description = "Hostnames for the above IP address.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ip" = mkOption {
          description = "IP address of the host file entry.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "hostnames" = mkOverride 1002 null;
        "ip" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.HostPathVolumeSource" = {

      options = {
        "path" = mkOption {
          description = "path of the directory on the host. If the path is a symlink, it will follow the link to the real path. More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = types.str;
        };
        "type" = mkOption {
          description = "type for HostPath Volume Defaults to \"\" More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ISCSIPersistentVolumeSource" = {

      options = {
        "chapAuthDiscovery" = mkOption {
          description = "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "chapAuthSession" = mkOption {
          description = "chapAuthSession defines whether support iSCSI Session CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi";
          type = (types.nullOr types.str);
        };
        "initiatorName" = mkOption {
          description = "initiatorName is the custom iSCSI Initiator Name. If initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface <target portal>:<volume name> will be created for the connection.";
          type = (types.nullOr types.str);
        };
        "iqn" = mkOption {
          description = "iqn is Target iSCSI Qualified Name.";
          type = types.str;
        };
        "iscsiInterface" = mkOption {
          description = "iscsiInterface is the interface Name that uses an iSCSI transport. Defaults to 'default' (tcp).";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun is iSCSI Target Lun number.";
          type = types.int;
        };
        "portals" = mkOption {
          description = "portals is the iSCSI Target Portal List. The Portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).";
          type = (types.nullOr (types.listOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is the CHAP Secret for iSCSI target and initiator authentication";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "targetPortal" = mkOption {
          description = "targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).";
          type = types.str;
        };
      };


      config = {
        "chapAuthDiscovery" = mkOverride 1002 null;
        "chapAuthSession" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "initiatorName" = mkOverride 1002 null;
        "iscsiInterface" = mkOverride 1002 null;
        "portals" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ISCSIVolumeSource" = {

      options = {
        "chapAuthDiscovery" = mkOption {
          description = "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "chapAuthSession" = mkOption {
          description = "chapAuthSession defines whether support iSCSI Session CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi";
          type = (types.nullOr types.str);
        };
        "initiatorName" = mkOption {
          description = "initiatorName is the custom iSCSI Initiator Name. If initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface <target portal>:<volume name> will be created for the connection.";
          type = (types.nullOr types.str);
        };
        "iqn" = mkOption {
          description = "iqn is the target iSCSI Qualified Name.";
          type = types.str;
        };
        "iscsiInterface" = mkOption {
          description = "iscsiInterface is the interface Name that uses an iSCSI transport. Defaults to 'default' (tcp).";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun represents iSCSI Target Lun number.";
          type = types.int;
        };
        "portals" = mkOption {
          description = "portals is the iSCSI Target Portal List. The portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).";
          type = (types.nullOr (types.listOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is the CHAP Secret for iSCSI target and initiator authentication";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "targetPortal" = mkOption {
          description = "targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).";
          type = types.str;
        };
      };


      config = {
        "chapAuthDiscovery" = mkOverride 1002 null;
        "chapAuthSession" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "initiatorName" = mkOverride 1002 null;
        "iscsiInterface" = mkOverride 1002 null;
        "portals" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.KeyToPath" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file. Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. If not specified, the volume defaultMode will be used. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to. May not be an absolute path. May not contain the path element '..'. May not start with the string '..'.";
          type = types.str;
        };
      };


      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Lifecycle" = {

      options = {
        "postStart" = mkOption {
          description = "PostStart is called immediately after a container is created. If the handler fails, the container is terminated and restarted according to its restart policy. Other management of the container blocks until the hook completes. More info: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LifecycleHandler"));
        };
        "preStop" = mkOption {
          description = "PreStop is called immediately before a container is terminated due to an API request or management event such as liveness/startup probe failure, preemption, resource contention, etc. The handler is not called if the container crashes or exits. The Pod's termination grace period countdown begins before the PreStop hook is executed. Regardless of the outcome of the handler, the container will eventually terminate within the Pod's termination grace period (unless delayed by finalizers). Other management of the container blocks until the hook completes or until the termination grace period is reached. More info: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LifecycleHandler"));
        };
      };


      config = {
        "postStart" = mkOverride 1002 null;
        "preStop" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LifecycleHandler" = {

      options = {
        "exec" = mkOption {
          description = "Exec specifies the action to take.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ExecAction"));
        };
        "httpGet" = mkOption {
          description = "HTTPGet specifies the http request to perform.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.HTTPGetAction"));
        };
        "tcpSocket" = mkOption {
          description = "Deprecated. TCPSocket is NOT supported as a LifecycleHandler and kept for the backward compatibility. There are no validation of this field and lifecycle hooks will fail in runtime when tcp handler is specified.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.TCPSocketAction"));
        };
      };


      config = {
        "exec" = mkOverride 1002 null;
        "httpGet" = mkOverride 1002 null;
        "tcpSocket" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LimitRange" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the limits enforced. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LimitRangeSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LimitRangeItem" = {

      options = {
        "default" = mkOption {
          description = "Default resource requirement limit value by resource name if resource limit is omitted.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "defaultRequest" = mkOption {
          description = "DefaultRequest is the default resource requirement request value by resource name if resource request is omitted.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "max" = mkOption {
          description = "Max usage constraints on this kind by resource name.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "maxLimitRequestRatio" = mkOption {
          description = "MaxLimitRequestRatio if specified, the named resource must have a request and limit that are both non-zero where limit divided by request is less than or equal to the enumerated value; this represents the max burst for the named resource.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "min" = mkOption {
          description = "Min usage constraints on this kind by resource name.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "type" = mkOption {
          description = "Type of resource that this limit applies to.";
          type = types.str;
        };
      };


      config = {
        "default" = mkOverride 1002 null;
        "defaultRequest" = mkOverride 1002 null;
        "max" = mkOverride 1002 null;
        "maxLimitRequestRatio" = mkOverride 1002 null;
        "min" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LimitRangeList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of LimitRange objects. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.LimitRange"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LimitRangeSpec" = {

      options = {
        "limits" = mkOption {
          description = "Limits is the list of LimitRangeItem objects that are enforced.";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.LimitRangeItem"));
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.LoadBalancerIngress" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is set for load-balancer ingress points that are DNS based (typically AWS load-balancers)";
          type = (types.nullOr types.str);
        };
        "ip" = mkOption {
          description = "IP is set for load-balancer ingress points that are IP based (typically GCE or OpenStack load-balancers)";
          type = (types.nullOr types.str);
        };
        "ports" = mkOption {
          description = "Ports is a list of records of service ports If used, every port defined in the service should have an entry in it";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PortStatus")));
        };
      };


      config = {
        "hostname" = mkOverride 1002 null;
        "ip" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LoadBalancerStatus" = {

      options = {
        "ingress" = mkOption {
          description = "Ingress is a list containing ingress points for the load-balancer. Traffic intended for the service should be sent to these ingress points.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.LoadBalancerIngress")));
        };
      };


      config = {
        "ingress" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LocalObjectReference" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.LocalVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. It applies only when the Path is a block device. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". The default value is to auto-select a filesystem if unspecified.";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "path of the full path to the volume on the node. It can be either a directory or block device (disk, partition, ...).";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NFSVolumeSource" = {

      options = {
        "path" = mkOption {
          description = "path that is exported by the NFS server. More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the NFS export to be mounted with read-only permissions. Defaults to false. More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (types.nullOr types.bool);
        };
        "server" = mkOption {
          description = "server is the hostname or IP address of the NFS server. More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
      };


      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Namespace" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the behavior of the Namespace. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NamespaceSpec"));
        };
        "status" = mkOption {
          description = "Status describes the current status of a Namespace. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NamespaceStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NamespaceCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of namespace controller condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NamespaceList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of Namespace objects in the list. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Namespace"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NamespaceSpec" = {

      options = {
        "finalizers" = mkOption {
          description = "Finalizers is an opaque list of values that must be empty to permanently remove object from storage. More info: https://kubernetes.io/docs/tasks/administer-cluster/namespaces/";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "finalizers" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NamespaceStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Represents the latest available observations of a namespace's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.NamespaceCondition" "type"));
          apply = attrsToList;
        };
        "phase" = mkOption {
          description = "Phase is the current lifecycle phase of the namespace. More info: https://kubernetes.io/docs/tasks/administer-cluster/namespaces/\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Node" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the behavior of a node. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSpec"));
        };
        "status" = mkOption {
          description = "Most recently observed status of the node. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeAddress" = {

      options = {
        "address" = mkOption {
          description = "The node address.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Node address type, one of Hostname, ExternalIP or InternalIP.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.NodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node matches the corresponding matchExpressions; the node(s) with the highest sum are the most preferred.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PreferredSchedulingTerm")));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to an update), the system may or may not try to eventually evict the pod from its node.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSelector"));
        };
      };


      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeCondition" = {

      options = {
        "lastHeartbeatTime" = mkOption {
          description = "Last time we got an update on a given condition.";
          type = (types.nullOr types.str);
        };
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transit from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Human readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "(brief) reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of node condition.";
          type = types.str;
        };
      };


      config = {
        "lastHeartbeatTime" = mkOverride 1002 null;
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeConfigSource" = {

      options = {
        "configMap" = mkOption {
          description = "ConfigMap is a reference to a Node's ConfigMap";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ConfigMapNodeConfigSource"));
        };
      };


      config = {
        "configMap" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeConfigStatus" = {

      options = {
        "active" = mkOption {
          description = "Active reports the checkpointed config the node is actively using. Active will represent either the current version of the Assigned config, or the current LastKnownGood config, depending on whether attempting to use the Assigned config results in an error.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeConfigSource"));
        };
        "assigned" = mkOption {
          description = "Assigned reports the checkpointed config the node will try to use. When Node.Spec.ConfigSource is updated, the node checkpoints the associated config payload to local disk, along with a record indicating intended config. The node refers to this record to choose its config checkpoint, and reports this record in Assigned. Assigned only updates in the status after the record has been checkpointed to disk. When the Kubelet is restarted, it tries to make the Assigned config the Active config by loading and validating the checkpointed payload identified by Assigned.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeConfigSource"));
        };
        "error" = mkOption {
          description = "Error describes any problems reconciling the Spec.ConfigSource to the Active config. Errors may occur, for example, attempting to checkpoint Spec.ConfigSource to the local Assigned record, attempting to checkpoint the payload associated with Spec.ConfigSource, attempting to load or validate the Assigned config, etc. Errors may occur at different points while syncing config. Earlier errors (e.g. download or checkpointing errors) will not result in a rollback to LastKnownGood, and may resolve across Kubelet retries. Later errors (e.g. loading or validating a checkpointed config) will result in a rollback to LastKnownGood. In the latter case, it is usually possible to resolve the error by fixing the config assigned in Spec.ConfigSource. You can find additional information for debugging by searching the error message in the Kubelet log. Error is a human-readable description of the error state; machines can check whether or not Error is empty, but should not rely on the stability of the Error text across Kubelet versions.";
          type = (types.nullOr types.str);
        };
        "lastKnownGood" = mkOption {
          description = "LastKnownGood reports the checkpointed config the node will fall back to when it encounters an error attempting to use the Assigned config. The Assigned config becomes the LastKnownGood config when the node determines that the Assigned config is stable and correct. This is currently implemented as a 10-minute soak period starting when the local record of Assigned config is updated. If the Assigned config is Active at the end of this period, it becomes the LastKnownGood. Note that if Spec.ConfigSource is reset to nil (use local defaults), the LastKnownGood is also immediately reset to nil, because the local default config is always assumed good. You should not make assumptions about the node's method of determining config stability and correctness, as this may change or become configurable in the future.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeConfigSource"));
        };
      };


      config = {
        "active" = mkOverride 1002 null;
        "assigned" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "lastKnownGood" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeDaemonEndpoints" = {

      options = {
        "kubeletEndpoint" = mkOption {
          description = "Endpoint on which Kubelet is listening.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.DaemonEndpoint"));
        };
      };


      config = {
        "kubeletEndpoint" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of nodes";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Node"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeSelector" = {

      options = {
        "nodeSelectorTerms" = mkOption {
          description = "Required. A list of node selector terms. The terms are ORed.";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.NodeSelectorTerm"));
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.NodeSelectorRequirement" = {

      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "Represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.\n\n";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. If the operator is Gt or Lt, the values array must have a single element, which will be interpreted as an integer. This array is replaced during a strategic merge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeSelectorTerm" = {

      options = {
        "matchExpressions" = mkOption {
          description = "A list of node selector requirements by node's labels.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.NodeSelectorRequirement")));
        };
        "matchFields" = mkOption {
          description = "A list of node selector requirements by node's fields.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.NodeSelectorRequirement")));
        };
      };


      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchFields" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeSpec" = {

      options = {
        "configSource" = mkOption {
          description = "Deprecated: Previously used to specify the source of the node's configuration for the DynamicKubeletConfig feature. This feature is removed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeConfigSource"));
        };
        "externalID" = mkOption {
          description = "Deprecated. Not all kubelets will set this field. Remove field after 1.13. see: https://issues.k8s.io/61966";
          type = (types.nullOr types.str);
        };
        "podCIDR" = mkOption {
          description = "PodCIDR represents the pod IP range assigned to the node.";
          type = (types.nullOr types.str);
        };
        "podCIDRs" = mkOption {
          description = "podCIDRs represents the IP ranges assigned to the node for usage by Pods on that node. If this field is specified, the 0th entry must match the podCIDR field. It may contain at most 1 value for each of IPv4 and IPv6.";
          type = (types.nullOr (types.listOf types.str));
        };
        "providerID" = mkOption {
          description = "ID of the node assigned by the cloud provider in the format: <ProviderName>://<ProviderSpecificNodeID>";
          type = (types.nullOr types.str);
        };
        "taints" = mkOption {
          description = "If specified, the node's taints.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.Taint")));
        };
        "unschedulable" = mkOption {
          description = "Unschedulable controls node schedulability of new pods. By default, node is schedulable. More info: https://kubernetes.io/docs/concepts/nodes/node/#manual-node-administration";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "configSource" = mkOverride 1002 null;
        "externalID" = mkOverride 1002 null;
        "podCIDR" = mkOverride 1002 null;
        "podCIDRs" = mkOverride 1002 null;
        "providerID" = mkOverride 1002 null;
        "taints" = mkOverride 1002 null;
        "unschedulable" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeStatus" = {

      options = {
        "addresses" = mkOption {
          description = "List of addresses reachable to the node. Queried from cloud provider, if available. More info: https://kubernetes.io/docs/concepts/nodes/node/#addresses Note: This field is declared as mergeable, but the merge key is not sufficiently unique, which can cause data corruption when it is merged. Callers should instead use a full-replacement patch. See https://pr.k8s.io/79391 for an example.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.NodeAddress" "type"));
          apply = attrsToList;
        };
        "allocatable" = mkOption {
          description = "Allocatable represents the resources of a node that are available for scheduling. Defaults to Capacity.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "capacity" = mkOption {
          description = "Capacity represents the total resources of a node. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#capacity";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "conditions" = mkOption {
          description = "Conditions is an array of current observed node conditions. More info: https://kubernetes.io/docs/concepts/nodes/node/#condition";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.NodeCondition" "type"));
          apply = attrsToList;
        };
        "config" = mkOption {
          description = "Status of the config assigned to the node via the dynamic Kubelet config feature.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeConfigStatus"));
        };
        "daemonEndpoints" = mkOption {
          description = "Endpoints of daemons running on the Node.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeDaemonEndpoints"));
        };
        "images" = mkOption {
          description = "List of container images on this node";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ContainerImage")));
        };
        "nodeInfo" = mkOption {
          description = "Set of ids/uuids to uniquely identify the node. More info: https://kubernetes.io/docs/concepts/nodes/node/#info";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSystemInfo"));
        };
        "phase" = mkOption {
          description = "NodePhase is the recently observed lifecycle phase of the node. More info: https://kubernetes.io/docs/concepts/nodes/node/#phase The field is never populated, and now is deprecated.\n\n";
          type = (types.nullOr types.str);
        };
        "volumesAttached" = mkOption {
          description = "List of volumes that are attached to the node.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.AttachedVolume")));
        };
        "volumesInUse" = mkOption {
          description = "List of attachable volumes in use (mounted) by the node.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "addresses" = mkOverride 1002 null;
        "allocatable" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "config" = mkOverride 1002 null;
        "daemonEndpoints" = mkOverride 1002 null;
        "images" = mkOverride 1002 null;
        "nodeInfo" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "volumesAttached" = mkOverride 1002 null;
        "volumesInUse" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.NodeSystemInfo" = {

      options = {
        "architecture" = mkOption {
          description = "The Architecture reported by the node";
          type = types.str;
        };
        "bootID" = mkOption {
          description = "Boot ID reported by the node.";
          type = types.str;
        };
        "containerRuntimeVersion" = mkOption {
          description = "ContainerRuntime Version reported by the node through runtime remote API (e.g. containerd://1.4.2).";
          type = types.str;
        };
        "kernelVersion" = mkOption {
          description = "Kernel Version reported by the node from 'uname -r' (e.g. 3.16.0-0.bpo.4-amd64).";
          type = types.str;
        };
        "kubeProxyVersion" = mkOption {
          description = "KubeProxy Version reported by the node.";
          type = types.str;
        };
        "kubeletVersion" = mkOption {
          description = "Kubelet Version reported by the node.";
          type = types.str;
        };
        "machineID" = mkOption {
          description = "MachineID reported by the node. For unique machine identification in the cluster this field is preferred. Learn more from man(5) machine-id: http://man7.org/linux/man-pages/man5/machine-id.5.html";
          type = types.str;
        };
        "operatingSystem" = mkOption {
          description = "The Operating System reported by the node";
          type = types.str;
        };
        "osImage" = mkOption {
          description = "OS Image reported by the node from /etc/os-release (e.g. Debian GNU/Linux 7 (wheezy)).";
          type = types.str;
        };
        "systemUUID" = mkOption {
          description = "SystemUUID reported by the node. For unique machine identification MachineID is preferred. This field is specific to Red Hat hosts https://access.redhat.com/documentation/en-us/red_hat_subscription_management/1/html/rhsm/uuid";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.ObjectFieldSelector" = {

      options = {
        "apiVersion" = mkOption {
          description = "Version of the schema the FieldPath is written in terms of, defaults to \"v1\".";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "Path of the field to select in the specified API version.";
          type = types.str;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ObjectReference" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "If referring to a piece of an object instead of an entire object, this string should contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2]. For example, if the object reference is to a container within a pod, this would take on a value like: \"spec.containers{name}\" (where \"name\" refers to the name of the container that triggered the event) or if no container name is specified \"spec.containers[2]\" (container with index 2 in this pod). This syntax is chosen only to have some well-defined way of referencing a part of an object.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/";
          type = (types.nullOr types.str);
        };
        "resourceVersion" = mkOption {
          description = "Specific resourceVersion to which this reference is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "fieldPath" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "resourceVersion" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolume" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec defines a specification of a persistent volume owned by the cluster. Provisioned by an administrator. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistent-volumes";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeSpec"));
        };
        "status" = mkOption {
          description = "status represents the current information/status for the persistent volume. Populated by the system. Read-only. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistent-volumes";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaim" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec defines the desired characteristics of a volume requested by a pod author. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaimSpec"));
        };
        "status" = mkOption {
          description = "status represents the current information/status of a persistent volume claim. Read-only. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaimStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimCondition" = {

      options = {
        "lastProbeTime" = mkOption {
          description = "lastProbeTime is the time we probed the condition.";
          type = (types.nullOr types.str);
        };
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "message is the human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is a unique, this should be a short, machine understandable string that gives the reason for condition's last transition. If it reports \"ResizeStarted\" that means the underlying persistent volume is being resized.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = types.str;
        };
        "type" = mkOption {
          description = "";
          type = types.str;
        };
      };


      config = {
        "lastProbeTime" = mkOverride 1002 null;
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is a list of persistent volume claims. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaim"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimSpec" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes contains the desired access modes the volume should have. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
          type = (types.nullOr (types.listOf types.str));
        };
        "dataSource" = mkOption {
          description = "dataSource field can be used to specify either: * An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot) * An existing PVC (PersistentVolumeClaim) If the provisioner or an external controller can support the specified data source, it will create a new volume based on the contents of the specified data source. When the AnyVolumeDataSource feature gate is enabled, dataSource contents will be copied to dataSourceRef, and dataSourceRef contents will be copied to dataSource when dataSourceRef.namespace is not specified. If the namespace is specified, then dataSourceRef will not be copied to dataSource.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.TypedLocalObjectReference"));
        };
        "dataSourceRef" = mkOption {
          description = "dataSourceRef specifies the object from which to populate the volume with data, if a non-empty volume is desired. This may be any object from a non-empty API group (non core object) or a PersistentVolumeClaim object. When this field is specified, volume binding will only succeed if the type of the specified object matches some installed volume populator or dynamic provisioner. This field will replace the functionality of the dataSource field and as such if both fields are non-empty, they must have the same value. For backwards compatibility, when namespace isn't specified in dataSourceRef, both fields (dataSource and dataSourceRef) will be set to the same value automatically if one of them is empty and the other is non-empty. When namespace is specified in dataSourceRef, dataSource isn't set to the same value and must be empty. There are three important differences between dataSource and dataSourceRef: * While dataSource only allows two specific types of objects, dataSourceRef\n  allows any non-core object, as well as PersistentVolumeClaim objects.\n* While dataSource ignores disallowed values (dropping them), dataSourceRef\n  preserves all values, and generates an error if a disallowed value is\n  specified.\n* While dataSource only allows local objects, dataSourceRef allows objects\n  in any namespaces.\n(Beta) Using this field requires the AnyVolumeDataSource feature gate to be enabled. (Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.TypedObjectReference"));
        };
        "resources" = mkOption {
          description = "resources represents the minimum resources the volume should have. If RecoverVolumeExpansionFailure feature is enabled users are allowed to specify resource requirements that are lower than previous value but must still be higher than capacity recorded in the status field of the claim. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceRequirements"));
        };
        "selector" = mkOption {
          description = "selector is a label query over volumes to consider for binding.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "storageClassName" = mkOption {
          description = "storageClassName is the name of the StorageClass required by the claim. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1";
          type = (types.nullOr types.str);
        };
        "volumeMode" = mkOption {
          description = "volumeMode defines what type of volume is required by the claim. Value of Filesystem is implied when not included in claim spec.";
          type = (types.nullOr types.str);
        };
        "volumeName" = mkOption {
          description = "volumeName is the binding reference to the PersistentVolume backing this claim.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "accessModes" = mkOverride 1002 null;
        "dataSource" = mkOverride 1002 null;
        "dataSourceRef" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimStatus" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes contains the actual access modes the volume backing the PVC has. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
          type = (types.nullOr (types.listOf types.str));
        };
        "allocatedResources" = mkOption {
          description = "allocatedResources is the storage resource within AllocatedResources tracks the capacity allocated to a PVC. It may be larger than the actual capacity when a volume expansion operation is requested. For storage quota, the larger value from allocatedResources and PVC.spec.resources is used. If allocatedResources is not set, PVC.spec.resources alone is used for quota calculation. If a volume expansion capacity request is lowered, allocatedResources is only lowered if there are no expansion operations in progress and if the actual volume capacity is equal or lower than the requested capacity. This is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "capacity" = mkOption {
          description = "capacity represents the actual resources of the underlying volume.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "conditions" = mkOption {
          description = "conditions is the current Condition of persistent volume claim. If underlying persistent volume is being resized then the Condition will be set to 'ResizeStarted'.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.PersistentVolumeClaimCondition" "type"));
          apply = attrsToList;
        };
        "phase" = mkOption {
          description = "phase represents the current phase of PersistentVolumeClaim.\n\n";
          type = (types.nullOr types.str);
        };
        "resizeStatus" = mkOption {
          description = "resizeStatus stores status of resize operation. ResizeStatus is not set by default but when expansion is complete resizeStatus is set to empty string by resize controller or kubelet. This is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "accessModes" = mkOverride 1002 null;
        "allocatedResources" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "resizeStatus" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "May contain labels and annotations that will be copied into the PVC when creating it. No other fields are allowed and will be rejected during validation.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "The specification for the PersistentVolumeClaim. The entire content is copied unchanged into the PVC that gets created from this template. The same fields as in a PersistentVolumeClaim are also valid here.";
          type = (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaimSpec");
        };
      };


      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeClaimVolumeSource" = {

      options = {
        "claimName" = mkOption {
          description = "claimName is the name of a PersistentVolumeClaim in the same namespace as the pod using this volume. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly Will force the ReadOnly setting in VolumeMounts. Default false.";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is a list of persistent volumes. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.PersistentVolume"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeSpec" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes contains all ways the volume can be mounted. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes";
          type = (types.nullOr (types.listOf types.str));
        };
        "awsElasticBlockStore" = mkOption {
          description = "awsElasticBlockStore represents an AWS Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AWSElasticBlockStoreVolumeSource"));
        };
        "azureDisk" = mkOption {
          description = "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AzureDiskVolumeSource"));
        };
        "azureFile" = mkOption {
          description = "azureFile represents an Azure File Service mount on the host and bind mount to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AzureFilePersistentVolumeSource"));
        };
        "capacity" = mkOption {
          description = "capacity is the description of the persistent volume's resources and capacity. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#capacity";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "cephfs" = mkOption {
          description = "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CephFSPersistentVolumeSource"));
        };
        "cinder" = mkOption {
          description = "cinder represents a cinder volume attached and mounted on kubelets host machine. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CinderPersistentVolumeSource"));
        };
        "claimRef" = mkOption {
          description = "claimRef is part of a bi-directional binding between PersistentVolume and PersistentVolumeClaim. Expected to be non-nil when bound. claim.VolumeName is the authoritative bind between PV and PVC. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#binding";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "csi" = mkOption {
          description = "csi represents storage that is handled by an external CSI driver (Beta feature).";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CSIPersistentVolumeSource"));
        };
        "fc" = mkOption {
          description = "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FCVolumeSource"));
        };
        "flexVolume" = mkOption {
          description = "flexVolume represents a generic volume resource that is provisioned/attached using an exec based plugin.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FlexPersistentVolumeSource"));
        };
        "flocker" = mkOption {
          description = "flocker represents a Flocker volume attached to a kubelet's host machine and exposed to the pod for its usage. This depends on the Flocker control service being running";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FlockerVolumeSource"));
        };
        "gcePersistentDisk" = mkOption {
          description = "gcePersistentDisk represents a GCE Disk resource that is attached to a kubelet's host machine and then exposed to the pod. Provisioned by an admin. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GCEPersistentDiskVolumeSource"));
        };
        "glusterfs" = mkOption {
          description = "glusterfs represents a Glusterfs volume that is attached to a host and exposed to the pod. Provisioned by an admin. More info: https://examples.k8s.io/volumes/glusterfs/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GlusterfsPersistentVolumeSource"));
        };
        "hostPath" = mkOption {
          description = "hostPath represents a directory on the host. Provisioned by a developer or tester. This is useful for single-node development and testing only! On-host storage is not supported in any way and WILL NOT WORK in a multi-node cluster. More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.HostPathVolumeSource"));
        };
        "iscsi" = mkOption {
          description = "iscsi represents an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod. Provisioned by an admin.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ISCSIPersistentVolumeSource"));
        };
        "local" = mkOption {
          description = "local represents directly-attached storage with node affinity";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalVolumeSource"));
        };
        "mountOptions" = mkOption {
          description = "mountOptions is the list of mount options, e.g. [\"ro\", \"soft\"]. Not validated - mount will simply fail if one is invalid. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#mount-options";
          type = (types.nullOr (types.listOf types.str));
        };
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host. Provisioned by an admin. More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NFSVolumeSource"));
        };
        "nodeAffinity" = mkOption {
          description = "nodeAffinity defines constraints that limit what nodes this volume can be accessed from. This field influences the scheduling of pods that use this volume.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.VolumeNodeAffinity"));
        };
        "persistentVolumeReclaimPolicy" = mkOption {
          description = "persistentVolumeReclaimPolicy defines what happens to a persistent volume when released from its claim. Valid options are Retain (default for manually created PersistentVolumes), Delete (default for dynamically provisioned PersistentVolumes), and Recycle (deprecated). Recycle must be supported by the volume plugin underlying this PersistentVolume. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#reclaiming\n\n";
          type = (types.nullOr types.str);
        };
        "photonPersistentDisk" = mkOption {
          description = "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PhotonPersistentDiskVolumeSource"));
        };
        "portworxVolume" = mkOption {
          description = "portworxVolume represents a portworx volume attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PortworxVolumeSource"));
        };
        "quobyte" = mkOption {
          description = "quobyte represents a Quobyte mount on the host that shares a pod's lifetime";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.QuobyteVolumeSource"));
        };
        "rbd" = mkOption {
          description = "rbd represents a Rados Block Device mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/rbd/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.RBDPersistentVolumeSource"));
        };
        "scaleIO" = mkOption {
          description = "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ScaleIOPersistentVolumeSource"));
        };
        "storageClassName" = mkOption {
          description = "storageClassName is the name of StorageClass to which this persistent volume belongs. Empty value means that this volume does not belong to any StorageClass.";
          type = (types.nullOr types.str);
        };
        "storageos" = mkOption {
          description = "storageOS represents a StorageOS volume that is attached to the kubelet's host machine and mounted into the pod More info: https://examples.k8s.io/volumes/storageos/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.StorageOSPersistentVolumeSource"));
        };
        "volumeMode" = mkOption {
          description = "volumeMode defines if a volume is intended to be used with a formatted filesystem or to remain in raw block state. Value of Filesystem is implied when not included in spec.";
          type = (types.nullOr types.str);
        };
        "vsphereVolume" = mkOption {
          description = "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.VsphereVirtualDiskVolumeSource"));
        };
      };


      config = {
        "accessModes" = mkOverride 1002 null;
        "awsElasticBlockStore" = mkOverride 1002 null;
        "azureDisk" = mkOverride 1002 null;
        "azureFile" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "cephfs" = mkOverride 1002 null;
        "cinder" = mkOverride 1002 null;
        "claimRef" = mkOverride 1002 null;
        "csi" = mkOverride 1002 null;
        "fc" = mkOverride 1002 null;
        "flexVolume" = mkOverride 1002 null;
        "flocker" = mkOverride 1002 null;
        "gcePersistentDisk" = mkOverride 1002 null;
        "glusterfs" = mkOverride 1002 null;
        "hostPath" = mkOverride 1002 null;
        "iscsi" = mkOverride 1002 null;
        "local" = mkOverride 1002 null;
        "mountOptions" = mkOverride 1002 null;
        "nfs" = mkOverride 1002 null;
        "nodeAffinity" = mkOverride 1002 null;
        "persistentVolumeReclaimPolicy" = mkOverride 1002 null;
        "photonPersistentDisk" = mkOverride 1002 null;
        "portworxVolume" = mkOverride 1002 null;
        "quobyte" = mkOverride 1002 null;
        "rbd" = mkOverride 1002 null;
        "scaleIO" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "storageos" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "vsphereVolume" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PersistentVolumeStatus" = {

      options = {
        "message" = mkOption {
          description = "message is a human-readable message indicating details about why the volume is in this state.";
          type = (types.nullOr types.str);
        };
        "phase" = mkOption {
          description = "phase indicates if a volume is available, bound to a claim, or released by a claim. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#phase\n\n";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is a brief CamelCase string that describes any failure and is meant for machine parsing and tidy display in the CLI.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "message" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PhotonPersistentDiskVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "pdID" = mkOption {
          description = "pdID is the ID that identifies Photon Controller persistent disk";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Pod" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the pod. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodSpec"));
        };
        "status" = mkOption {
          description = "Most recently observed status of the pod. This data may not be up to date. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.WeightedPodAffinityTerm")));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PodAffinityTerm")));
        };
      };


      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodAffinityTerm" = {

      options = {
        "labelSelector" = mkOption {
          description = "A label query over a set of resources, in this case pods.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "namespaceSelector" = mkOption {
          description = "A label query over the set of namespaces that the term applies to. The term is applied to the union of the namespaces selected by this field and the ones listed in the namespaces field. null selector and null or empty namespaces list means \"this pod's namespace\". An empty selector ({}) matches all namespaces.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "namespaces" = mkOption {
          description = "namespaces specifies a static list of namespace names that the term applies to. The term is applied to the union of the namespaces listed in this field and the ones selected by namespaceSelector. null or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
          type = (types.nullOr (types.listOf types.str));
        };
        "topologyKey" = mkOption {
          description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching the labelSelector in the specified namespaces, where co-located is defined as running on a node whose value of the label with key topologyKey matches that of any node on which any of the selected pods is running. Empty topologyKey is not allowed.";
          type = types.str;
        };
      };


      config = {
        "labelSelector" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy the anti-affinity expressions specified by this field, but it may choose a node that violates one or more of the expressions. The node that is most preferred is the one with the greatest sum of weights, i.e. for each node that meets all of the scheduling requirements (resource request, requiredDuringScheduling anti-affinity expressions, etc.), compute a sum by iterating through the elements of this field and adding \"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the node(s) with the highest sum are the most preferred.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.WeightedPodAffinityTerm")));
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at scheduling time, the pod will not be scheduled onto the node. If the anti-affinity requirements specified by this field cease to be met at some point during pod execution (e.g. due to a pod label update), the system may or may not try to eventually evict the pod from its node. When there are multiple elements, the lists of nodes corresponding to each podAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PodAffinityTerm")));
        };
      };


      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodCondition" = {

      options = {
        "lastProbeTime" = mkOption {
          description = "Last time we probed the condition.";
          type = (types.nullOr types.str);
        };
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "Unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status is the status of the condition. Can be True, False, Unknown. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type is the type of the condition. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions";
          type = types.str;
        };
      };


      config = {
        "lastProbeTime" = mkOverride 1002 null;
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodDNSConfig" = {

      options = {
        "nameservers" = mkOption {
          description = "A list of DNS name server IP addresses. This will be appended to the base nameservers generated from DNSPolicy. Duplicated nameservers will be removed.";
          type = (types.nullOr (types.listOf types.str));
        };
        "options" = mkOption {
          description = "A list of DNS resolver options. This will be merged with the base options generated from DNSPolicy. Duplicated entries will be removed. Resolution options given in Options will override those that appear in the base DNSPolicy.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PodDNSConfigOption")));
        };
        "searches" = mkOption {
          description = "A list of DNS search domains for host-name lookup. This will be appended to the base search paths generated from DNSPolicy. Duplicated search paths will be removed.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "nameservers" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "searches" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodDNSConfigOption" = {

      options = {
        "name" = mkOption {
          description = "Required.";
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
    "io.k8s.api.core.v1.PodIP" = {

      options = {
        "ip" = mkOption {
          description = "ip is an IP address (IPv4 or IPv6) assigned to the pod";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "ip" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of pods. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Pod"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodOS" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the operating system. The currently supported values are linux and windows. Additional value may be defined in future and can be one of: https://github.com/opencontainers/runtime-spec/blob/master/config.md#platform-specific-configuration Clients should expect to handle additional values and treat unrecognized values in this field as os: null";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.PodReadinessGate" = {

      options = {
        "conditionType" = mkOption {
          description = "ConditionType refers to a condition in the pod's condition list with matching type.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.PodResourceClaim" = {

      options = {
        "name" = mkOption {
          description = "Name uniquely identifies this resource claim inside the pod. This must be a DNS_LABEL.";
          type = types.str;
        };
        "source" = mkOption {
          description = "Source describes where to find the ResourceClaim.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ClaimSource"));
        };
      };


      config = {
        "source" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodSchedulingGate" = {

      options = {
        "name" = mkOption {
          description = "Name of the scheduling gate. Each scheduling gate must have a unique name field.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.PodSecurityContext" = {

      options = {
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod. Some volume types allow the Kubelet to change the ownership of that volume to be owned by the pod:\n\n1. The owning GID will be the FSGroup 2. The setgid bit is set (new files created in the volume will be owned by FSGroup) 3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume before being exposed inside Pod. This field will only apply to volume types which support fsGroup based ownership(and permissions). It will have no effect on ephemeral volume types such as: secret, configmaps and emptydir. Valid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process. Uses runtime default if unset. May also be set in SecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence for that container. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user. If true, the Kubelet will validate the image at runtime to ensure that it does not run as UID 0 (root) and fail to start the container if it does. If unset or false, no such validation will be performed. May also be set in SecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process. Defaults to user specified in image metadata if unspecified. May also be set in SecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence for that container. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers. If unspecified, the container runtime will allocate a random SELinux context for each container.  May also be set in SecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence for that container. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SELinuxOptions"));
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SeccompProfile"));
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in addition to the container's primary GID, the fsGroup (if specified), and group memberships defined in the container image for the uid of the container process. If unspecified, no additional groups are added to any container. Note that group memberships defined in the container image for the uid of the container process are still effective, even if they are not included in this list. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported sysctls (by the container runtime) might fail to launch. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.Sysctl")));
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers. If unspecified, the options within a container's SecurityContext will be used. If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence. Note that this field cannot be set when spec.os.name is linux.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.WindowsSecurityContextOptions"));
        };
      };


      config = {
        "fsGroup" = mkOverride 1002 null;
        "fsGroupChangePolicy" = mkOverride 1002 null;
        "runAsGroup" = mkOverride 1002 null;
        "runAsNonRoot" = mkOverride 1002 null;
        "runAsUser" = mkOverride 1002 null;
        "seLinuxOptions" = mkOverride 1002 null;
        "seccompProfile" = mkOverride 1002 null;
        "supplementalGroups" = mkOverride 1002 null;
        "sysctls" = mkOverride 1002 null;
        "windowsOptions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodSpec" = {

      options = {
        "activeDeadlineSeconds" = mkOption {
          description = "Optional duration in seconds the pod may be active on the node relative to StartTime before the system will actively try to mark it failed and kill associated containers. Value must be a positive integer.";
          type = (types.nullOr types.int);
        };
        "affinity" = mkOption {
          description = "If specified, the pod's scheduling constraints";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Affinity"));
        };
        "automountServiceAccountToken" = mkOption {
          description = "AutomountServiceAccountToken indicates whether a service account token should be automatically mounted.";
          type = (types.nullOr types.bool);
        };
        "containers" = mkOption {
          description = "List of containers belonging to the pod. Containers cannot currently be added or removed. There must be at least one container in a Pod. Cannot be updated.";
          type = (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.Container" "name");
          apply = attrsToList;
        };
        "dnsConfig" = mkOption {
          description = "Specifies the DNS parameters of a pod. Parameters specified here will be merged to the generated DNS configuration based on DNSPolicy.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodDNSConfig"));
        };
        "dnsPolicy" = mkOption {
          description = "Set DNS policy for the pod. Defaults to \"ClusterFirst\". Valid values are 'ClusterFirstWithHostNet', 'ClusterFirst', 'Default' or 'None'. DNS parameters given in DNSConfig will be merged with the policy selected with DNSPolicy. To have DNS options set along with hostNetwork, you have to specify DNS policy explicitly to 'ClusterFirstWithHostNet'.\n\n";
          type = (types.nullOr types.str);
        };
        "enableServiceLinks" = mkOption {
          description = "EnableServiceLinks indicates whether information about services should be injected into pod's environment variables, matching the syntax of Docker links. Optional: Defaults to true.";
          type = (types.nullOr types.bool);
        };
        "ephemeralContainers" = mkOption {
          description = "List of ephemeral containers run in this pod. Ephemeral containers may be run in an existing pod to perform user-initiated actions such as debugging. This list cannot be specified when creating a pod, and it cannot be modified by updating the pod spec. In order to add an ephemeral container to an existing pod, use the pod's ephemeralcontainers subresource.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.EphemeralContainer" "name"));
          apply = attrsToList;
        };
        "hostAliases" = mkOption {
          description = "HostAliases is an optional list of hosts and IPs that will be injected into the pod's hosts file if specified. This is only valid for non-hostNetwork pods.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.HostAlias" "ip"));
          apply = attrsToList;
        };
        "hostIPC" = mkOption {
          description = "Use the host's ipc namespace. Optional: Default to false.";
          type = (types.nullOr types.bool);
        };
        "hostNetwork" = mkOption {
          description = "Host networking requested for this pod. Use the host's network namespace. If this option is set, the ports that will be used must be specified. Default to false.";
          type = (types.nullOr types.bool);
        };
        "hostPID" = mkOption {
          description = "Use the host's pid namespace. Optional: Default to false.";
          type = (types.nullOr types.bool);
        };
        "hostUsers" = mkOption {
          description = "Use the host's user namespace. Optional: Default to true. If set to true or not present, the pod will be run in the host user namespace, useful for when the pod needs a feature only available to the host user namespace, such as loading a kernel module with CAP_SYS_MODULE. When set to false, a new userns is created for the pod. Setting false is useful for mitigating container breakout vulnerabilities even allowing users to run their containers as root without actually having root privileges on the host. This field is alpha-level and is only honored by servers that enable the UserNamespacesSupport feature.";
          type = (types.nullOr types.bool);
        };
        "hostname" = mkOption {
          description = "Specifies the hostname of the Pod If not specified, the pod's hostname will be set to a system-defined value.";
          type = (types.nullOr types.str);
        };
        "imagePullSecrets" = mkOption {
          description = "ImagePullSecrets is an optional list of references to secrets in the same namespace to use for pulling any of the images used by this PodSpec. If specified, these secrets will be passed to individual puller implementations for them to use. More info: https://kubernetes.io/docs/concepts/containers/images#specifying-imagepullsecrets-on-a-pod";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.LocalObjectReference" "name"));
          apply = attrsToList;
        };
        "initContainers" = mkOption {
          description = "List of initialization containers belonging to the pod. Init containers are executed in order prior to containers being started. If any init container fails, the pod is considered to have failed and is handled according to its restartPolicy. The name for an init container or normal container must be unique among all containers. Init containers may not have Lifecycle actions, Readiness probes, Liveness probes, or Startup probes. The resourceRequirements of an init container are taken into account during scheduling by finding the highest request/limit for each resource type, and then using the max of of that value or the sum of the normal containers. Limits are applied to init containers in a similar fashion. Init containers cannot currently be added or removed. Cannot be updated. More info: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.Container" "name"));
          apply = attrsToList;
        };
        "nodeName" = mkOption {
          description = "NodeName is a request to schedule this pod onto a specific node. If it is non-empty, the scheduler simply schedules this pod onto that node, assuming that it fits resource requirements.";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector is a selector which must be true for the pod to fit on a node. Selector which must match a node's labels for the pod to be scheduled on that node. More info: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "os" = mkOption {
          description = "Specifies the OS of the containers in the pod. Some pod and container fields are restricted if this is set.\n\nIf the OS field is set to linux, the following fields must be unset: -securityContext.windowsOptions\n\nIf the OS field is set to windows, following fields must be unset: - spec.hostPID - spec.hostIPC - spec.hostUsers - spec.securityContext.seLinuxOptions - spec.securityContext.seccompProfile - spec.securityContext.fsGroup - spec.securityContext.fsGroupChangePolicy - spec.securityContext.sysctls - spec.shareProcessNamespace - spec.securityContext.runAsUser - spec.securityContext.runAsGroup - spec.securityContext.supplementalGroups - spec.containers[*].securityContext.seLinuxOptions - spec.containers[*].securityContext.seccompProfile - spec.containers[*].securityContext.capabilities - spec.containers[*].securityContext.readOnlyRootFilesystem - spec.containers[*].securityContext.privileged - spec.containers[*].securityContext.allowPrivilegeEscalation - spec.containers[*].securityContext.procMount - spec.containers[*].securityContext.runAsUser - spec.containers[*].securityContext.runAsGroup";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodOS"));
        };
        "overhead" = mkOption {
          description = "Overhead represents the resource overhead associated with running a pod for a given RuntimeClass. This field will be autopopulated at admission time by the RuntimeClass admission controller. If the RuntimeClass admission controller is enabled, overhead must not be set in Pod create requests. The RuntimeClass admission controller will reject Pod create requests which have the overhead already set. If RuntimeClass is configured and selected in the PodSpec, Overhead will be set to the value defined in the corresponding RuntimeClass, otherwise it will remain unset and treated as zero. More info: https://git.k8s.io/enhancements/keps/sig-node/688-pod-overhead/README.md";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "preemptionPolicy" = mkOption {
          description = "PreemptionPolicy is the Policy for preempting pods with lower priority. One of Never, PreemptLowerPriority. Defaults to PreemptLowerPriority if unset.";
          type = (types.nullOr types.str);
        };
        "priority" = mkOption {
          description = "The priority value. Various system components use this field to find the priority of the pod. When Priority Admission Controller is enabled, it prevents users from setting this field. The admission controller populates this field from PriorityClassName. The higher the value, the higher the priority.";
          type = (types.nullOr types.int);
        };
        "priorityClassName" = mkOption {
          description = "If specified, indicates the pod's priority. \"system-node-critical\" and \"system-cluster-critical\" are two special keywords which indicate the highest priorities with the former being the highest priority. Any other name must be defined by creating a PriorityClass object with that name. If not specified, the pod priority will be default or zero if there is no default.";
          type = (types.nullOr types.str);
        };
        "readinessGates" = mkOption {
          description = "If specified, all readiness gates will be evaluated for pod readiness. A pod is ready when all its containers are ready AND all conditions specified in the readiness gates have status equal to \"True\" More info: https://git.k8s.io/enhancements/keps/sig-network/580-pod-readiness-gates";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.PodReadinessGate")));
        };
        "resourceClaims" = mkOption {
          description = "ResourceClaims defines which ResourceClaims must be allocated and reserved before the Pod is allowed to start. The resources will be made available to those containers which consume them by name.\n\nThis is an alpha field and requires enabling the DynamicResourceAllocation feature gate.\n\nThis field is immutable.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.PodResourceClaim" "name"));
          apply = attrsToList;
        };
        "restartPolicy" = mkOption {
          description = "Restart policy for all containers within the pod. One of Always, OnFailure, Never. Default to Always. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy\n\n";
          type = (types.nullOr types.str);
        };
        "runtimeClassName" = mkOption {
          description = "RuntimeClassName refers to a RuntimeClass object in the node.k8s.io group, which should be used to run this pod.  If no RuntimeClass resource matches the named class, the pod will not be run. If unset or empty, the \"legacy\" RuntimeClass will be used, which is an implicit class with an empty definition that uses the default runtime handler. More info: https://git.k8s.io/enhancements/keps/sig-node/585-runtime-class";
          type = (types.nullOr types.str);
        };
        "schedulerName" = mkOption {
          description = "If specified, the pod will be dispatched by specified scheduler. If not specified, the pod will be dispatched by default scheduler.";
          type = (types.nullOr types.str);
        };
        "schedulingGates" = mkOption {
          description = "SchedulingGates is an opaque list of values that if specified will block scheduling the pod. More info:  https://git.k8s.io/enhancements/keps/sig-scheduling/3521-pod-scheduling-readiness.\n\nThis is an alpha-level feature enabled by PodSchedulingReadiness feature gate.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.PodSchedulingGate" "name"));
          apply = attrsToList;
        };
        "securityContext" = mkOption {
          description = "SecurityContext holds pod-level security attributes and common container settings. Optional: Defaults to empty.  See type description for default values of each field.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodSecurityContext"));
        };
        "serviceAccount" = mkOption {
          description = "DeprecatedServiceAccount is a depreciated alias for ServiceAccountName. Deprecated: Use serviceAccountName instead.";
          type = (types.nullOr types.str);
        };
        "serviceAccountName" = mkOption {
          description = "ServiceAccountName is the name of the ServiceAccount to use to run this pod. More info: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/";
          type = (types.nullOr types.str);
        };
        "setHostnameAsFQDN" = mkOption {
          description = "If true the pod's hostname will be configured as the pod's FQDN, rather than the leaf name (the default). In Linux containers, this means setting the FQDN in the hostname field of the kernel (the nodename field of struct utsname). In Windows containers, this means setting the registry value of hostname for the registry key HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters to FQDN. If a pod does not have FQDN, this has no effect. Default to false.";
          type = (types.nullOr types.bool);
        };
        "shareProcessNamespace" = mkOption {
          description = "Share a single process namespace between all of the containers in a pod. When this is set containers will be able to view and signal processes from other containers in the same pod, and the first process in each container will not be assigned PID 1. HostPID and ShareProcessNamespace cannot both be set. Optional: Default to false.";
          type = (types.nullOr types.bool);
        };
        "subdomain" = mkOption {
          description = "If specified, the fully qualified Pod hostname will be \"<hostname>.<subdomain>.<pod namespace>.svc.<cluster domain>\". If not specified, the pod will not have a domainname at all.";
          type = (types.nullOr types.str);
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "Optional duration in seconds the pod needs to terminate gracefully. May be decreased in delete request. Value must be non-negative integer. The value zero indicates stop immediately via the kill signal (no opportunity to shut down). If this value is nil, the default grace period will be used instead. The grace period is the duration in seconds after the processes running in the pod are sent a termination signal and the time when the processes are forcibly halted with a kill signal. Set this value longer than the expected cleanup time for your process. Defaults to 30 seconds.";
          type = (types.nullOr types.int);
        };
        "tolerations" = mkOption {
          description = "If specified, the pod's tolerations.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.Toleration")));
        };
        "topologySpreadConstraints" = mkOption {
          description = "TopologySpreadConstraints describes how a group of pods ought to spread across topology domains. Scheduler will schedule pods in a way which abides by the constraints. All topologySpreadConstraints are ANDed.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.TopologySpreadConstraint" "topologyKey"));
          apply = attrsToList;
        };
        "volumes" = mkOption {
          description = "List of volumes that can be mounted by containers belonging to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.Volume" "name"));
          apply = attrsToList;
        };
      };


      config = {
        "activeDeadlineSeconds" = mkOverride 1002 null;
        "affinity" = mkOverride 1002 null;
        "automountServiceAccountToken" = mkOverride 1002 null;
        "dnsConfig" = mkOverride 1002 null;
        "dnsPolicy" = mkOverride 1002 null;
        "enableServiceLinks" = mkOverride 1002 null;
        "ephemeralContainers" = mkOverride 1002 null;
        "hostAliases" = mkOverride 1002 null;
        "hostIPC" = mkOverride 1002 null;
        "hostNetwork" = mkOverride 1002 null;
        "hostPID" = mkOverride 1002 null;
        "hostUsers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "initContainers" = mkOverride 1002 null;
        "nodeName" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "os" = mkOverride 1002 null;
        "overhead" = mkOverride 1002 null;
        "preemptionPolicy" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "readinessGates" = mkOverride 1002 null;
        "resourceClaims" = mkOverride 1002 null;
        "restartPolicy" = mkOverride 1002 null;
        "runtimeClassName" = mkOverride 1002 null;
        "schedulerName" = mkOverride 1002 null;
        "schedulingGates" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "setHostnameAsFQDN" = mkOverride 1002 null;
        "shareProcessNamespace" = mkOverride 1002 null;
        "subdomain" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
        "topologySpreadConstraints" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state of pod. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.PodCondition" "type"));
          apply = attrsToList;
        };
        "containerStatuses" = mkOption {
          description = "The list has one entry per container in the manifest. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-and-container-status";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ContainerStatus")));
        };
        "ephemeralContainerStatuses" = mkOption {
          description = "Status for any ephemeral containers that have run in this pod.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ContainerStatus")));
        };
        "hostIP" = mkOption {
          description = "IP address of the host to which the pod is assigned. Empty if not yet scheduled.";
          type = (types.nullOr types.str);
        };
        "initContainerStatuses" = mkOption {
          description = "The list has one entry per init container in the manifest. The most recent successful init container will have ready = true, the most recently started container will have startTime set. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-and-container-status";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ContainerStatus")));
        };
        "message" = mkOption {
          description = "A human readable message indicating details about why the pod is in this condition.";
          type = (types.nullOr types.str);
        };
        "nominatedNodeName" = mkOption {
          description = "nominatedNodeName is set only when this pod preempts other pods on the node, but it cannot be scheduled right away as preemption victims receive their graceful termination periods. This field does not guarantee that the pod will be scheduled on this node. Scheduler may decide to place the pod elsewhere if other nodes become available sooner. Scheduler may also decide to give the resources on this node to a higher priority pod that is created after preemption. As a result, this field may be different than PodSpec.nodeName when the pod is scheduled.";
          type = (types.nullOr types.str);
        };
        "phase" = mkOption {
          description = "The phase of a Pod is a simple, high-level summary of where the Pod is in its lifecycle. The conditions array, the reason and message fields, and the individual container status arrays contain more detail about the pod's status. There are five possible phase values:\n\nPending: The pod has been accepted by the Kubernetes system, but one or more of the container images has not been created. This includes time before being scheduled as well as time spent downloading images over the network, which could take a while. Running: The pod has been bound to a node, and all of the containers have been created. At least one container is still running, or is in the process of starting or restarting. Succeeded: All containers in the pod have terminated in success, and will not be restarted. Failed: All containers in the pod have terminated, and at least one container has terminated in failure. The container either exited with non-zero status or was terminated by the system. Unknown: For some reason the state of the pod could not be obtained, typically due to an error in communicating with the host of the pod.\n\nMore info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-phase\n\n";
          type = (types.nullOr types.str);
        };
        "podIP" = mkOption {
          description = "IP address allocated to the pod. Routable at least within the cluster. Empty if not yet allocated.";
          type = (types.nullOr types.str);
        };
        "podIPs" = mkOption {
          description = "podIPs holds the IP addresses allocated to the pod. If this field is specified, the 0th entry must match the podIP field. Pods may be allocated at most 1 value for each of IPv4 and IPv6. This list is empty if no IPs have been allocated yet.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.PodIP" "ip"));
          apply = attrsToList;
        };
        "qosClass" = mkOption {
          description = "The Quality of Service (QOS) classification assigned to the pod based on resource requirements See PodQOSClass type for available QOS classes More info: https://git.k8s.io/community/contributors/design-proposals/node/resource-qos.md\n\n";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "A brief CamelCase message indicating details about why the pod is in this state. e.g. 'Evicted'";
          type = (types.nullOr types.str);
        };
        "startTime" = mkOption {
          description = "RFC 3339 date and time at which the object was acknowledged by the Kubelet. This is before the Kubelet pulled the container image(s) for the pod.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "containerStatuses" = mkOverride 1002 null;
        "ephemeralContainerStatuses" = mkOverride 1002 null;
        "hostIP" = mkOverride 1002 null;
        "initContainerStatuses" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "nominatedNodeName" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "podIP" = mkOverride 1002 null;
        "podIPs" = mkOverride 1002 null;
        "qosClass" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "startTime" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodTemplate" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "template" = mkOption {
          description = "Template defines the pods that will be created from this pod template. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodTemplateList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of pod templates";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.PodTemplate"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PodTemplateSpec" = {

      options = {
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the pod. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodSpec"));
        };
      };


      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PortStatus" = {

      options = {
        "error" = mkOption {
          description = "Error is to record the problem with the service port The format of the error shall comply with the following rules: - built-in error values shall be specified in this file and those shall use\n  CamelCase names\n- cloud provider specific error values must have names that comply with the\n  format foo.example.com/CamelCase.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "Port is the port number of the service port of which status is recorded here";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "Protocol is the protocol of the service port of which status is recorded here The supported values are: \"TCP\", \"UDP\", \"SCTP\"\n\n";
          type = types.str;
        };
      };


      config = {
        "error" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PortworxVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fSType represents the filesystem type to mount Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID uniquely identifies a Portworx volume";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.PreferredSchedulingTerm" = {

      options = {
        "preference" = mkOption {
          description = "A node selector term, associated with the corresponding weight.";
          type = (submoduleOf "io.k8s.api.core.v1.NodeSelectorTerm");
        };
        "weight" = mkOption {
          description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
          type = types.int;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.Probe" = {

      options = {
        "exec" = mkOption {
          description = "Exec specifies the action to take.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ExecAction"));
        };
        "failureThreshold" = mkOption {
          description = "Minimum consecutive failures for the probe to be considered failed after having succeeded. Defaults to 3. Minimum value is 1.";
          type = (types.nullOr types.int);
        };
        "grpc" = mkOption {
          description = "GRPC specifies an action involving a GRPC port. This is a beta field and requires enabling GRPCContainerProbe feature gate.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GRPCAction"));
        };
        "httpGet" = mkOption {
          description = "HTTPGet specifies the http request to perform.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.HTTPGetAction"));
        };
        "initialDelaySeconds" = mkOption {
          description = "Number of seconds after the container has started before liveness probes are initiated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes";
          type = (types.nullOr types.int);
        };
        "periodSeconds" = mkOption {
          description = "How often (in seconds) to perform the probe. Default to 10 seconds. Minimum value is 1.";
          type = (types.nullOr types.int);
        };
        "successThreshold" = mkOption {
          description = "Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. Must be 1 for liveness and startup. Minimum value is 1.";
          type = (types.nullOr types.int);
        };
        "tcpSocket" = mkOption {
          description = "TCPSocket specifies an action involving a TCP port.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.TCPSocketAction"));
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "Optional duration in seconds the pod needs to terminate gracefully upon probe failure. The grace period is the duration in seconds after the processes running in the pod are sent a termination signal and the time when the processes are forcibly halted with a kill signal. Set this value longer than the expected cleanup time for your process. If this value is nil, the pod's terminationGracePeriodSeconds will be used. Otherwise, this value overrides the value provided by the pod spec. Value must be non-negative integer. The value zero indicates stop immediately via the kill signal (no opportunity to shut down). This is a beta field and requires enabling ProbeTerminationGracePeriod feature gate. Minimum value is 1. spec.terminationGracePeriodSeconds is used if unset.";
          type = (types.nullOr types.int);
        };
        "timeoutSeconds" = mkOption {
          description = "Number of seconds after which the probe times out. Defaults to 1 second. Minimum value is 1. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "exec" = mkOverride 1002 null;
        "failureThreshold" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "httpGet" = mkOverride 1002 null;
        "initialDelaySeconds" = mkOverride 1002 null;
        "periodSeconds" = mkOverride 1002 null;
        "successThreshold" = mkOverride 1002 null;
        "tcpSocket" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ProjectedVolumeSource" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode are the mode bits used to set permissions on created files by default. Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. Directories within the path are not affected by this setting. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "sources" = mkOption {
          description = "sources is the list of volume projections";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.VolumeProjection")));
        };
      };


      config = {
        "defaultMode" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.QuobyteVolumeSource" = {

      options = {
        "group" = mkOption {
          description = "group to map volume access to Default is no group";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Quobyte volume to be mounted with read-only permissions. Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "registry" = mkOption {
          description = "registry represents a single or multiple Quobyte Registry services specified as a string as host:port pair (multiple entries are separated with commas) which acts as the central registry for volumes";
          type = types.str;
        };
        "tenant" = mkOption {
          description = "tenant owning the given Quobyte volume in the Backend Used with dynamically provisioned Quobyte volumes, value is set by the plugin";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "user to map volume access to Defaults to serivceaccount user";
          type = (types.nullOr types.str);
        };
        "volume" = mkOption {
          description = "volume is a string that references an already created Quobyte volume by name.";
          type = types.str;
        };
      };


      config = {
        "group" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "tenant" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.RBDPersistentVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#rbd";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "image is the rados image name. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = types.str;
        };
        "keyring" = mkOption {
          description = "keyring is the path to key ring for RBDUser. Default is /etc/ceph/keyring. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "monitors" = mkOption {
          description = "monitors is a collection of Ceph monitors. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "pool" = mkOption {
          description = "pool is the rados pool name. Default is rbd. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is name of the authentication secret for RBDUser. If provided overrides keyring. Default is nil. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretReference"));
        };
        "user" = mkOption {
          description = "user is the rados user name. Default is admin. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "keyring" = mkOverride 1002 null;
        "pool" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.RBDVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#rbd";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "image is the rados image name. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = types.str;
        };
        "keyring" = mkOption {
          description = "keyring is the path to key ring for RBDUser. Default is /etc/ceph/keyring. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "monitors" = mkOption {
          description = "monitors is a collection of Ceph monitors. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "pool" = mkOption {
          description = "pool is the rados pool name. Default is rbd. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is name of the authentication secret for RBDUser. If provided overrides keyring. Default is nil. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "user" = mkOption {
          description = "user is the rados user name. Default is admin. More info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "keyring" = mkOverride 1002 null;
        "pool" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ReplicationController" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "If the Labels of a ReplicationController are empty, they are defaulted to be the same as the Pod(s) that the replication controller manages. Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the specification of the desired behavior of the replication controller. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ReplicationControllerSpec"));
        };
        "status" = mkOption {
          description = "Status is the most recently observed status of the replication controller. This data may be out of date by some window of time. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ReplicationControllerStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ReplicationControllerCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "The last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human readable message indicating details about the transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "The reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type of replication controller condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ReplicationControllerList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of replication controllers. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.ReplicationController"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ReplicationControllerSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "Minimum number of seconds for which a newly created pod should be ready without any of its container crashing, for it to be considered available. Defaults to 0 (pod will be considered available as soon as it is ready)";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Replicas is the number of desired replicas. This is a pointer to distinguish between explicit zero and unspecified. Defaults to 1. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#what-is-a-replicationcontroller";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "Selector is a label query over pods that should match the Replicas count. If Selector is empty, it is defaulted to the labels present on the Pod template. Label keys and values that must match in order to be controlled by this replication controller, if empty defaulted to labels on Pod template. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "template" = mkOption {
          description = "Template is the object that describes the pod that will be created if insufficient replicas are detected. This takes precedence over a TemplateRef. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#pod-template";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PodTemplateSpec"));
        };
      };


      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ReplicationControllerStatus" = {

      options = {
        "availableReplicas" = mkOption {
          description = "The number of available replicas (ready for at least minReadySeconds) for this replication controller.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Represents the latest available observations of a replication controller's current state.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ReplicationControllerCondition" "type"));
          apply = attrsToList;
        };
        "fullyLabeledReplicas" = mkOption {
          description = "The number of pods that have labels matching the labels of the pod template of the replication controller.";
          type = (types.nullOr types.int);
        };
        "observedGeneration" = mkOption {
          description = "ObservedGeneration reflects the generation of the most recently observed replication controller.";
          type = (types.nullOr types.int);
        };
        "readyReplicas" = mkOption {
          description = "The number of ready replicas for this replication controller.";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "Replicas is the most recently observed number of replicas. More info: https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller#what-is-a-replicationcontroller";
          type = types.int;
        };
      };


      config = {
        "availableReplicas" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "fullyLabeledReplicas" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "readyReplicas" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceClaim" = {

      options = {
        "name" = mkOption {
          description = "Name must match the name of one entry in pod.spec.resourceClaims of the Pod where this field is used. It makes that resource available inside a container.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.ResourceFieldSelector" = {

      options = {
        "containerName" = mkOption {
          description = "Container name: required for volumes, optional for env vars";
          type = (types.nullOr types.str);
        };
        "divisor" = mkOption {
          description = "Specifies the output format of the exposed resources, defaults to \"1\"";
          type = (types.nullOr types.str);
        };
        "resource" = mkOption {
          description = "Required: resource to select";
          type = types.str;
        };
      };


      config = {
        "containerName" = mkOverride 1002 null;
        "divisor" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceQuota" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the desired quota. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceQuotaSpec"));
        };
        "status" = mkOption {
          description = "Status defines the actual enforced quota and its current usage. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ResourceQuotaStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceQuotaList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of ResourceQuota objects. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.ResourceQuota"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceQuotaSpec" = {

      options = {
        "hard" = mkOption {
          description = "hard is the set of desired hard limits for each named resource. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "scopeSelector" = mkOption {
          description = "scopeSelector is also a collection of filters like scopes that must match each object tracked by a quota but expressed using ScopeSelectorOperator in combination with possible values. For a resource to match, both scopes AND scopeSelector (if specified in spec), must be matched.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ScopeSelector"));
        };
        "scopes" = mkOption {
          description = "A collection of filters that must match each object tracked by a quota. If not specified, the quota matches all objects.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "hard" = mkOverride 1002 null;
        "scopeSelector" = mkOverride 1002 null;
        "scopes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceQuotaStatus" = {

      options = {
        "hard" = mkOption {
          description = "Hard is the set of enforced hard limits for each named resource. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "used" = mkOption {
          description = "Used is the current observed total usage of the resource in the namespace.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };


      config = {
        "hard" = mkOverride 1002 null;
        "used" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ResourceRequirements" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims, that are used by this container.\n\nThis is an alpha field and requires enabling the DynamicResourceAllocation feature gate.\n\nThis field is immutable.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ResourceClaim")));
        };
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required. If Requests is omitted for a container, it defaults to Limits if that is explicitly specified, otherwise to an implementation-defined value. More info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };


      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SELinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "level" = mkOverride 1002 null;
        "role" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ScaleIOPersistentVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Default is \"xfs\"";
          type = (types.nullOr types.str);
        };
        "gateway" = mkOption {
          description = "gateway is the host address of the ScaleIO API Gateway.";
          type = types.str;
        };
        "protectionDomain" = mkOption {
          description = "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef references to the secret for ScaleIO user and other sensitive information. If this is not provided, Login operation will fail.";
          type = (submoduleOf "io.k8s.api.core.v1.SecretReference");
        };
        "sslEnabled" = mkOption {
          description = "sslEnabled is the flag to enable/disable SSL communication with Gateway, default false";
          type = (types.nullOr types.bool);
        };
        "storageMode" = mkOption {
          description = "storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned. Default is ThinProvisioned.";
          type = (types.nullOr types.str);
        };
        "storagePool" = mkOption {
          description = "storagePool is the ScaleIO Storage Pool associated with the protection domain.";
          type = (types.nullOr types.str);
        };
        "system" = mkOption {
          description = "system is the name of the storage system as configured in ScaleIO.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "volumeName is the name of a volume already created in the ScaleIO system that is associated with this volume source.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "protectionDomain" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "sslEnabled" = mkOverride 1002 null;
        "storageMode" = mkOverride 1002 null;
        "storagePool" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ScaleIOVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Default is \"xfs\".";
          type = (types.nullOr types.str);
        };
        "gateway" = mkOption {
          description = "gateway is the host address of the ScaleIO API Gateway.";
          type = types.str;
        };
        "protectionDomain" = mkOption {
          description = "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef references to the secret for ScaleIO user and other sensitive information. If this is not provided, Login operation will fail.";
          type = (submoduleOf "io.k8s.api.core.v1.LocalObjectReference");
        };
        "sslEnabled" = mkOption {
          description = "sslEnabled Flag enable/disable SSL communication with Gateway, default false";
          type = (types.nullOr types.bool);
        };
        "storageMode" = mkOption {
          description = "storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned. Default is ThinProvisioned.";
          type = (types.nullOr types.str);
        };
        "storagePool" = mkOption {
          description = "storagePool is the ScaleIO Storage Pool associated with the protection domain.";
          type = (types.nullOr types.str);
        };
        "system" = mkOption {
          description = "system is the name of the storage system as configured in ScaleIO.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "volumeName is the name of a volume already created in the ScaleIO system that is associated with this volume source.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "protectionDomain" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "sslEnabled" = mkOverride 1002 null;
        "storageMode" = mkOverride 1002 null;
        "storagePool" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ScopeSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "A list of scope selector requirements by scope of the resources.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.ScopedResourceSelectorRequirement")));
        };
      };


      config = {
        "matchExpressions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ScopedResourceSelectorRequirement" = {

      options = {
        "operator" = mkOption {
          description = "Represents a scope's relationship to a set of values. Valid operators are In, NotIn, Exists, DoesNotExist.\n\n";
          type = types.str;
        };
        "scopeName" = mkOption {
          description = "The name of the scope that the selector applies to.\n\n";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used. The profile must be preconfigured on the node to work. Must be a descending path, relative to the kubelet's configured seccomp profile location. Must only be set if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied. Valid options are:\n\nLocalhost - a profile defined in a file on the node should be used. RuntimeDefault - the container runtime default profile should be used. Unconfined - no profile should be applied.\n\n";
          type = types.str;
        };
      };


      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Secret" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "data" = mkOption {
          description = "Data contains the secret data. Each key must consist of alphanumeric characters, '-', '_' or '.'. The serialized form of the secret data is a base64 encoded string, representing the arbitrary (possibly non-string) data value here. Described in https://tools.ietf.org/html/rfc4648#section-4";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "immutable" = mkOption {
          description = "Immutable, if set to true, ensures that data stored in the Secret cannot be updated (only object metadata can be modified). If not set to true, the field can be modified at any time. Defaulted to nil.";
          type = (types.nullOr types.bool);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "stringData" = mkOption {
          description = "stringData allows specifying non-binary secret data in string form. It is provided as a write-only input field for convenience. All keys and values are merged into the data field on write, overwriting any existing values. The stringData field is never output when reading from the API.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "type" = mkOption {
          description = "Used to facilitate programmatic handling of secret data. More info: https://kubernetes.io/docs/concepts/configuration/secret/#secret-types";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "data" = mkOverride 1002 null;
        "immutable" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "stringData" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretEnvSource" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretKeySelector" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of secret objects. More info: https://kubernetes.io/docs/concepts/configuration/secret";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Secret"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretProjection" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced Secret will be projected into the volume as a file whose name is the key and content is the value. If specified, the listed keys will be projected into the specified paths, and unlisted keys will not be present. If a key is specified which is not present in the Secret, the volume setup will error unless it is marked optional. Paths must be relative and may not contain the '..' path or start with '..'.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.KeyToPath")));
        };
        "name" = mkOption {
          description = "Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretReference" = {

      options = {
        "name" = mkOption {
          description = "name is unique within a namespace to reference a secret resource.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "namespace defines the space within which the secret name must be unique.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecretVolumeSource" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default. Must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. Defaults to 0644. Directories within the path are not affected by this setting. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced Secret will be projected into the volume as a file whose name is the key and content is the value. If specified, the listed keys will be projected into the specified paths, and unlisted keys will not be present. If a key is specified which is not present in the Secret, the volume setup will error unless it is marked optional. Paths must be relative and may not contain the '..' path or start with '..'.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.KeyToPath")));
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its keys must be defined";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the name of the secret in the pod's namespace to use. More info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SecurityContext" = {

      options = {
        "allowPrivilegeEscalation" = mkOption {
          description = "AllowPrivilegeEscalation controls whether a process can gain more privileges than its parent process. This bool directly controls if the no_new_privs flag will be set on the container process. AllowPrivilegeEscalation is true always when the container is: 1) run as Privileged 2) has CAP_SYS_ADMIN Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.bool);
        };
        "capabilities" = mkOption {
          description = "The capabilities to add/drop when running containers. Defaults to the default set of capabilities granted by the container runtime. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.Capabilities"));
        };
        "privileged" = mkOption {
          description = "Run container in privileged mode. Processes in privileged containers are essentially equivalent to root on the host. Defaults to false. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.bool);
        };
        "procMount" = mkOption {
          description = "procMount denotes the type of proc mount to use for the containers. The default is DefaultProcMount which uses the container runtime defaults for readonly paths and masked paths. This requires the ProcMountType feature flag to be enabled. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "readOnlyRootFilesystem" = mkOption {
          description = "Whether this container has a read-only root filesystem. Default is false. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.bool);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process. Uses runtime default if unset. May also be set in PodSecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user. If true, the Kubelet will validate the image at runtime to ensure that it does not run as UID 0 (root) and fail to start the container if it does. If unset or false, no such validation will be performed. May also be set in PodSecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process. Defaults to user specified in image metadata if unspecified. May also be set in PodSecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to the container. If unspecified, the container runtime will allocate a random SELinux context for each container.  May also be set in PodSecurityContext.  If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SELinuxOptions"));
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by this container. If seccomp options are provided at both the pod & container level, the container options override the pod options. Note that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SeccompProfile"));
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers. If unspecified, the options from the PodSecurityContext will be used. If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence. Note that this field cannot be set when spec.os.name is linux.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.WindowsSecurityContextOptions"));
        };
      };


      config = {
        "allowPrivilegeEscalation" = mkOverride 1002 null;
        "capabilities" = mkOverride 1002 null;
        "privileged" = mkOverride 1002 null;
        "procMount" = mkOverride 1002 null;
        "readOnlyRootFilesystem" = mkOverride 1002 null;
        "runAsGroup" = mkOverride 1002 null;
        "runAsNonRoot" = mkOverride 1002 null;
        "runAsUser" = mkOverride 1002 null;
        "seLinuxOptions" = mkOverride 1002 null;
        "seccompProfile" = mkOverride 1002 null;
        "windowsOptions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Service" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec defines the behavior of a service. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ServiceSpec"));
        };
        "status" = mkOption {
          description = "Most recently observed status of the service. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ServiceStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceAccount" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "automountServiceAccountToken" = mkOption {
          description = "AutomountServiceAccountToken indicates whether pods running as this service account should have an API token automatically mounted. Can be overridden at the pod level.";
          type = (types.nullOr types.bool);
        };
        "imagePullSecrets" = mkOption {
          description = "ImagePullSecrets is a list of references to secrets in the same namespace to use for pulling any images in pods that reference this ServiceAccount. ImagePullSecrets are distinct from Secrets because Secrets can be mounted in the pod, but ImagePullSecrets are only accessed by the kubelet. More info: https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.LocalObjectReference")));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "secrets" = mkOption {
          description = "Secrets is a list of the secrets in the same namespace that pods running using this ServiceAccount are allowed to use. Pods are only limited to this list if this service account has a \"kubernetes.io/enforce-mountable-secrets\" annotation set to \"true\". This field should not be used to find auto-generated service account token secrets for use outside of pods. Instead, tokens can be requested directly using the TokenRequest API, or service account token secrets can be manually created. More info: https://kubernetes.io/docs/concepts/configuration/secret";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ObjectReference" "name"));
          apply = attrsToList;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "automountServiceAccountToken" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "secrets" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceAccountList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of ServiceAccounts. More info: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.ServiceAccount"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceAccountTokenProjection" = {

      options = {
        "audience" = mkOption {
          description = "audience is the intended audience of the token. A recipient of a token must identify itself with an identifier specified in the audience of the token, and otherwise should reject the token. The audience defaults to the identifier of the apiserver.";
          type = (types.nullOr types.str);
        };
        "expirationSeconds" = mkOption {
          description = "expirationSeconds is the requested duration of validity of the service account token. As the token approaches expiration, the kubelet volume plugin will proactively rotate the service account token. The kubelet will start trying to rotate the token if the token is older than 80 percent of its time to live or if the token is older than 24 hours.Defaults to 1 hour and must be at least 10 minutes.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the path relative to the mount point of the file to project the token into.";
          type = types.str;
        };
      };


      config = {
        "audience" = mkOverride 1002 null;
        "expirationSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of services";
          type = (types.listOf (submoduleOf "io.k8s.api.core.v1.Service"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServicePort" = {

      options = {
        "appProtocol" = mkOption {
          description = "The application protocol for this port. This field follows standard Kubernetes label syntax. Un-prefixed names are reserved for IANA standard service names (as per RFC-6335 and https://www.iana.org/assignments/service-names). Non-standard protocols should use prefixed names such as mycompany.com/my-custom-protocol.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of this port within the service. This must be a DNS_LABEL. All ports within a ServiceSpec must have unique names. When considering the endpoints for a Service, this must match the 'name' field in the EndpointPort. Optional if only one ServicePort is defined on this service.";
          type = (types.nullOr types.str);
        };
        "nodePort" = mkOption {
          description = "The port on each node on which this service is exposed when type is NodePort or LoadBalancer.  Usually assigned by the system. If a value is specified, in-range, and not in use it will be used, otherwise the operation will fail.  If not specified, a port will be allocated if this Service requires one.  If this field is specified when creating a Service which does not need it, creation will fail. This field will be wiped when updating a Service to no longer need it (e.g. changing type from NodePort to ClusterIP). More info: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport";
          type = (types.nullOr types.int);
        };
        "port" = mkOption {
          description = "The port that will be exposed by this service.";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "The IP protocol for this port. Supports \"TCP\", \"UDP\", and \"SCTP\". Default is TCP.\n\n";
          type = (types.nullOr types.str);
        };
        "targetPort" = mkOption {
          description = "Number or name of the port to access on the pods targeted by the service. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME. If this is a string, it will be looked up as a named port in the target Pod's container ports. If this is not specified, the value of the 'port' field is used (an identity map). This field is ignored for services with clusterIP=None, and should be omitted or set equal to the 'port' field. More info: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service";
          type = (types.nullOr (types.either types.int types.str));
        };
      };


      config = {
        "appProtocol" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nodePort" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
        "targetPort" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceSpec" = {

      options = {
        "allocateLoadBalancerNodePorts" = mkOption {
          description = "allocateLoadBalancerNodePorts defines if NodePorts will be automatically allocated for services with type LoadBalancer.  Default is \"true\". It may be set to \"false\" if the cluster load-balancer does not rely on NodePorts.  If the caller requests specific NodePorts (by specifying a value), those requests will be respected, regardless of this field. This field may only be set for services with type LoadBalancer and will be cleared if the type is changed to any other type.";
          type = (types.nullOr types.bool);
        };
        "clusterIP" = mkOption {
          description = "clusterIP is the IP address of the service and is usually assigned randomly. If an address is specified manually, is in-range (as per system configuration), and is not in use, it will be allocated to the service; otherwise creation of the service will fail. This field may not be changed through updates unless the type field is also being changed to ExternalName (which requires this field to be blank) or the type field is being changed from ExternalName (in which case this field may optionally be specified, as describe above).  Valid values are \"None\", empty string (\"\"), or a valid IP address. Setting this to \"None\" makes a \"headless service\" (no virtual IP), which is useful when direct endpoint connections are preferred and proxying is not required.  Only applies to types ClusterIP, NodePort, and LoadBalancer. If this field is specified when creating a Service of type ExternalName, creation will fail. This field will be wiped when updating a Service to type ExternalName. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr types.str);
        };
        "clusterIPs" = mkOption {
          description = "ClusterIPs is a list of IP addresses assigned to this service, and are usually assigned randomly.  If an address is specified manually, is in-range (as per system configuration), and is not in use, it will be allocated to the service; otherwise creation of the service will fail. This field may not be changed through updates unless the type field is also being changed to ExternalName (which requires this field to be empty) or the type field is being changed from ExternalName (in which case this field may optionally be specified, as describe above).  Valid values are \"None\", empty string (\"\"), or a valid IP address.  Setting this to \"None\" makes a \"headless service\" (no virtual IP), which is useful when direct endpoint connections are preferred and proxying is not required.  Only applies to types ClusterIP, NodePort, and LoadBalancer. If this field is specified when creating a Service of type ExternalName, creation will fail. This field will be wiped when updating a Service to type ExternalName.  If this field is not specified, it will be initialized from the clusterIP field.  If this field is specified, clients must ensure that clusterIPs[0] and clusterIP have the same value.\n\nThis field may hold a maximum of two entries (dual-stack IPs, in either order). These IPs must correspond to the values of the ipFamilies field. Both clusterIPs and ipFamilies are governed by the ipFamilyPolicy field. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalIPs" = mkOption {
          description = "externalIPs is a list of IP addresses for which nodes in the cluster will also accept traffic for this service.  These IPs are not managed by Kubernetes.  The user is responsible for ensuring that traffic arrives at a node with this IP.  A common example is external load-balancers that are not part of the Kubernetes system.";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalName" = mkOption {
          description = "externalName is the external reference that discovery mechanisms will return as an alias for this service (e.g. a DNS CNAME record). No proxying will be involved.  Must be a lowercase RFC-1123 hostname (https://tools.ietf.org/html/rfc1123) and requires `type` to be \"ExternalName\".";
          type = (types.nullOr types.str);
        };
        "externalTrafficPolicy" = mkOption {
          description = "externalTrafficPolicy describes how nodes distribute service traffic they receive on one of the Service's \"externally-facing\" addresses (NodePorts, ExternalIPs, and LoadBalancer IPs). If set to \"Local\", the proxy will configure the service in a way that assumes that external load balancers will take care of balancing the service traffic between nodes, and so each node will deliver traffic only to the node-local endpoints of the service, without masquerading the client source IP. (Traffic mistakenly sent to a node with no endpoints will be dropped.) The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features). Note that traffic sent to an External IP or LoadBalancer IP from within the cluster will always get \"Cluster\" semantics, but clients sending to a NodePort from within the cluster may need to take traffic policy into account when picking a node.\n\n";
          type = (types.nullOr types.str);
        };
        "healthCheckNodePort" = mkOption {
          description = "healthCheckNodePort specifies the healthcheck nodePort for the service. This only applies when type is set to LoadBalancer and externalTrafficPolicy is set to Local. If a value is specified, is in-range, and is not in use, it will be used.  If not specified, a value will be automatically allocated.  External systems (e.g. load-balancers) can use this port to determine if a given node holds endpoints for this service or not.  If this field is specified when creating a Service which does not need it, creation will fail. This field will be wiped when updating a Service to no longer need it (e.g. changing type). This field cannot be updated once set.";
          type = (types.nullOr types.int);
        };
        "internalTrafficPolicy" = mkOption {
          description = "InternalTrafficPolicy describes how nodes distribute service traffic they receive on the ClusterIP. If set to \"Local\", the proxy will assume that pods only want to talk to endpoints of the service on the same node as the pod, dropping the traffic if there are no local endpoints. The default value, \"Cluster\", uses the standard behavior of routing to all endpoints evenly (possibly modified by topology and other features).";
          type = (types.nullOr types.str);
        };
        "ipFamilies" = mkOption {
          description = "IPFamilies is a list of IP families (e.g. IPv4, IPv6) assigned to this service. This field is usually assigned automatically based on cluster configuration and the ipFamilyPolicy field. If this field is specified manually, the requested family is available in the cluster, and ipFamilyPolicy allows it, it will be used; otherwise creation of the service will fail. This field is conditionally mutable: it allows for adding or removing a secondary IP family, but it does not allow changing the primary IP family of the Service. Valid values are \"IPv4\" and \"IPv6\".  This field only applies to Services of types ClusterIP, NodePort, and LoadBalancer, and does apply to \"headless\" services. This field will be wiped when updating a Service to type ExternalName.\n\nThis field may hold a maximum of two entries (dual-stack families, in either order).  These families must correspond to the values of the clusterIPs field, if specified. Both clusterIPs and ipFamilies are governed by the ipFamilyPolicy field.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ipFamilyPolicy" = mkOption {
          description = "IPFamilyPolicy represents the dual-stack-ness requested or required by this Service. If there is no value provided, then this field will be set to SingleStack. Services can be \"SingleStack\" (a single IP family), \"PreferDualStack\" (two IP families on dual-stack configured clusters or a single IP family on single-stack clusters), or \"RequireDualStack\" (two IP families on dual-stack configured clusters, otherwise fail). The ipFamilies and clusterIPs fields depend on the value of this field. This field will be wiped when updating a service to type ExternalName.";
          type = (types.nullOr types.str);
        };
        "loadBalancerClass" = mkOption {
          description = "loadBalancerClass is the class of the load balancer implementation this Service belongs to. If specified, the value of this field must be a label-style identifier, with an optional prefix, e.g. \"internal-vip\" or \"example.com/internal-vip\". Unprefixed names are reserved for end-users. This field can only be set when the Service type is 'LoadBalancer'. If not set, the default load balancer implementation is used, today this is typically done through the cloud provider integration, but should apply for any default implementation. If set, it is assumed that a load balancer implementation is watching for Services with a matching class. Any default load balancer implementation (e.g. cloud providers) should ignore Services that set this field. This field can only be set when creating or updating a Service to type 'LoadBalancer'. Once set, it can not be changed. This field will be wiped when a service is updated to a non 'LoadBalancer' type.";
          type = (types.nullOr types.str);
        };
        "loadBalancerIP" = mkOption {
          description = "Only applies to Service Type: LoadBalancer. This feature depends on whether the underlying cloud-provider supports specifying the loadBalancerIP when a load balancer is created. This field will be ignored if the cloud-provider does not support the feature. Deprecated: This field was under-specified and its meaning varies across implementations, and it cannot support dual-stack. As of Kubernetes v1.24, users are encouraged to use implementation-specific annotations when available. This field may be removed in a future API version.";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "If specified and supported by the platform, this will restrict traffic through the cloud-provider load-balancer will be restricted to the specified client IPs. This field will be ignored if the cloud-provider does not support the feature.\" More info: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/";
          type = (types.nullOr (types.listOf types.str));
        };
        "ports" = mkOption {
          description = "The list of ports that are exposed by this service. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.core.v1.ServicePort" "port"));
          apply = attrsToList;
        };
        "publishNotReadyAddresses" = mkOption {
          description = "publishNotReadyAddresses indicates that any agent which deals with endpoints for this Service should disregard any indications of ready/not-ready. The primary use case for setting this field is for a StatefulSet's Headless Service to propagate SRV DNS records for its Pods for the purpose of peer discovery. The Kubernetes controllers that generate Endpoints and EndpointSlice resources for Services interpret this to mean that all endpoints are considered \"ready\" even if the Pods themselves are not. Agents which consume only Kubernetes generated endpoints through the Endpoints or EndpointSlice resources can safely assume this behavior.";
          type = (types.nullOr types.bool);
        };
        "selector" = mkOption {
          description = "Route service traffic to pods with label keys and values matching this selector. If empty or not present, the service is assumed to have an external process managing its endpoints, which Kubernetes will not modify. Only applies to types ClusterIP, NodePort, and LoadBalancer. Ignored if type is ExternalName. More info: https://kubernetes.io/docs/concepts/services-networking/service/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "sessionAffinity" = mkOption {
          description = "Supports \"ClientIP\" and \"None\". Used to maintain session affinity. Enable client IP based session affinity. Must be ClientIP or None. Defaults to None. More info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies\n\n";
          type = (types.nullOr types.str);
        };
        "sessionAffinityConfig" = mkOption {
          description = "sessionAffinityConfig contains the configurations of session affinity.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SessionAffinityConfig"));
        };
        "type" = mkOption {
          description = "type determines how the Service is exposed. Defaults to ClusterIP. Valid options are ExternalName, ClusterIP, NodePort, and LoadBalancer. \"ClusterIP\" allocates a cluster-internal IP address for load-balancing to endpoints. Endpoints are determined by the selector or if that is not specified, by manual construction of an Endpoints object or EndpointSlice objects. If clusterIP is \"None\", no virtual IP is allocated and the endpoints are published as a set of endpoints rather than a virtual IP. \"NodePort\" builds on ClusterIP and allocates a port on every node which routes to the same endpoints as the clusterIP. \"LoadBalancer\" builds on NodePort and creates an external load-balancer (if supported in the current cloud) which routes to the same endpoints as the clusterIP. \"ExternalName\" aliases this service to the specified externalName. Several other fields do not apply to ExternalName services. More info: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types\n\n";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "allocateLoadBalancerNodePorts" = mkOverride 1002 null;
        "clusterIP" = mkOverride 1002 null;
        "clusterIPs" = mkOverride 1002 null;
        "externalIPs" = mkOverride 1002 null;
        "externalName" = mkOverride 1002 null;
        "externalTrafficPolicy" = mkOverride 1002 null;
        "healthCheckNodePort" = mkOverride 1002 null;
        "internalTrafficPolicy" = mkOverride 1002 null;
        "ipFamilies" = mkOverride 1002 null;
        "ipFamilyPolicy" = mkOverride 1002 null;
        "loadBalancerClass" = mkOverride 1002 null;
        "loadBalancerIP" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "publishNotReadyAddresses" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "sessionAffinity" = mkOverride 1002 null;
        "sessionAffinityConfig" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.ServiceStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.apimachinery.pkg.apis.meta.v1.Condition" "type"));
          apply = attrsToList;
        };
        "loadBalancer" = mkOption {
          description = "LoadBalancer contains the current status of the load-balancer, if one is present.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LoadBalancerStatus"));
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "loadBalancer" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.SessionAffinityConfig" = {

      options = {
        "clientIP" = mkOption {
          description = "clientIP contains the configurations of Client IP based session affinity.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ClientIPConfig"));
        };
      };


      config = {
        "clientIP" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.StorageOSPersistentVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef specifies the secret to use for obtaining the StorageOS API credentials.  If not specified, default values will be attempted.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "volumeName" = mkOption {
          description = "volumeName is the human-readable name of the StorageOS volume.  Volume names are only unique within a namespace.";
          type = (types.nullOr types.str);
        };
        "volumeNamespace" = mkOption {
          description = "volumeNamespace specifies the scope of the volume within StorageOS.  If no namespace is specified then the Pod's namespace will be used.  This allows the Kubernetes name scoping to be mirrored within StorageOS for tighter integration. Set VolumeName to any name to override the default behaviour. Set to \"default\" if you are not using namespaces within StorageOS. Namespaces that do not pre-exist within StorageOS will be created.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
        "volumeNamespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.StorageOSVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef specifies the secret to use for obtaining the StorageOS API credentials.  If not specified, default values will be attempted.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.LocalObjectReference"));
        };
        "volumeName" = mkOption {
          description = "volumeName is the human-readable name of the StorageOS volume.  Volume names are only unique within a namespace.";
          type = (types.nullOr types.str);
        };
        "volumeNamespace" = mkOption {
          description = "volumeNamespace specifies the scope of the volume within StorageOS.  If no namespace is specified then the Pod's namespace will be used.  This allows the Kubernetes name scoping to be mirrored within StorageOS for tighter integration. Set VolumeName to any name to override the default behaviour. Set to \"default\" if you are not using namespaces within StorageOS. Namespaces that do not pre-exist within StorageOS will be created.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
        "volumeNamespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Sysctl" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.TCPSocketAction" = {

      options = {
        "host" = mkOption {
          description = "Optional: Host name to connect to, defaults to the pod IP.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "Number or name of the port to access on the container. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.";
          type = (types.either types.int types.str);
        };
      };


      config = {
        "host" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Taint" = {

      options = {
        "effect" = mkOption {
          description = "Required. The effect of the taint on pods that do not tolerate the taint. Valid effects are NoSchedule, PreferNoSchedule and NoExecute.\n\n";
          type = types.str;
        };
        "key" = mkOption {
          description = "Required. The taint key to be applied to a node.";
          type = types.str;
        };
        "timeAdded" = mkOption {
          description = "TimeAdded represents the time at which the taint was added. It is only written for NoExecute taints.";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "The taint value corresponding to the taint key.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "timeAdded" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Toleration" = {

      options = {
        "effect" = mkOption {
          description = "Effect indicates the taint effect to match. Empty means match all taint effects. When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.\n\n";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Key is the taint key that the toleration applies to. Empty means match all taint keys. If the key is empty, operator must be Exists; this combination means to match all values and all keys.";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "Operator represents a key's relationship to the value. Valid operators are Exists and Equal. Defaults to Equal. Exists is equivalent to wildcard for value, so that a pod can tolerate all taints of a particular category.\n\n";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "TolerationSeconds represents the period of time the toleration (which must be of effect NoExecute, otherwise this field is ignored) tolerates the taint. By default, it is not set, which means tolerate the taint forever (do not evict). Zero and negative values will be treated as 0 (evict immediately) by the system.";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "Value is the taint value the toleration matches to. If the operator is Exists, the value should be empty, otherwise just a regular string.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.TopologySelectorLabelRequirement" = {

      options = {
        "key" = mkOption {
          description = "The label key that the selector applies to.";
          type = types.str;
        };
        "values" = mkOption {
          description = "An array of string values. One value must match the label to be selected. Each entry in Values is ORed.";
          type = (types.listOf types.str);
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.TopologySelectorTerm" = {

      options = {
        "matchLabelExpressions" = mkOption {
          description = "A list of topology selector requirements by labels.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.TopologySelectorLabelRequirement")));
        };
      };


      config = {
        "matchLabelExpressions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.TopologySpreadConstraint" = {

      options = {
        "labelSelector" = mkOption {
          description = "LabelSelector is used to find matching pods. Pods that match this label selector are counted to determine the number of pods in their corresponding topology domain.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "matchLabelKeys" = mkOption {
          description = "MatchLabelKeys is a set of pod label keys to select the pods over which spreading will be calculated. The keys are used to lookup values from the incoming pod labels, those key-value labels are ANDed with labelSelector to select the group of existing pods over which spreading will be calculated for the incoming pod. Keys that don't exist in the incoming pod labels will be ignored. A null or empty list means only match against labelSelector.";
          type = (types.nullOr (types.listOf types.str));
        };
        "maxSkew" = mkOption {
          description = "MaxSkew describes the degree to which pods may be unevenly distributed. When `whenUnsatisfiable=DoNotSchedule`, it is the maximum permitted difference between the number of matching pods in the target topology and the global minimum. The global minimum is the minimum number of matching pods in an eligible domain or zero if the number of eligible domains is less than MinDomains. For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same labelSelector spread as 2/2/1: In this case, the global minimum is 1. | zone1 | zone2 | zone3 | |  P P  |  P P  |   P   | - if MaxSkew is 1, incoming pod can only be scheduled to zone3 to become 2/2/2; scheduling it onto zone1(zone2) would make the ActualSkew(3-1) on zone1(zone2) violate MaxSkew(1). - if MaxSkew is 2, incoming pod can be scheduled onto any zone. When `whenUnsatisfiable=ScheduleAnyway`, it is used to give higher precedence to topologies that satisfy it. It's a required field. Default value is 1 and 0 is not allowed.";
          type = types.int;
        };
        "minDomains" = mkOption {
          description = "MinDomains indicates a minimum number of eligible domains. When the number of eligible domains with matching topology keys is less than minDomains, Pod Topology Spread treats \"global minimum\" as 0, and then the calculation of Skew is performed. And when the number of eligible domains with matching topology keys equals or greater than minDomains, this value has no effect on scheduling. As a result, when the number of eligible domains is less than minDomains, scheduler won't schedule more than maxSkew Pods to those domains. If value is nil, the constraint behaves as if MinDomains is equal to 1. Valid values are integers greater than 0. When value is not nil, WhenUnsatisfiable must be DoNotSchedule.\n\nFor example, in a 3-zone cluster, MaxSkew is set to 2, MinDomains is set to 5 and pods with the same labelSelector spread as 2/2/2: | zone1 | zone2 | zone3 | |  P P  |  P P  |  P P  | The number of domains is less than 5(MinDomains), so \"global minimum\" is treated as 0. In this situation, new pod with the same labelSelector cannot be scheduled, because computed skew will be 3(3 - 0) if new Pod is scheduled to any of the three zones, it will violate MaxSkew.\n\nThis is a beta field and requires the MinDomainsInPodTopologySpread feature gate to be enabled (enabled by default).";
          type = (types.nullOr types.int);
        };
        "nodeAffinityPolicy" = mkOption {
          description = "NodeAffinityPolicy indicates how we will treat Pod's nodeAffinity/nodeSelector when calculating pod topology spread skew. Options are: - Honor: only nodes matching nodeAffinity/nodeSelector are included in the calculations. - Ignore: nodeAffinity/nodeSelector are ignored. All nodes are included in the calculations.\n\nIf this value is nil, the behavior is equivalent to the Honor policy. This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.";
          type = (types.nullOr types.str);
        };
        "nodeTaintsPolicy" = mkOption {
          description = "NodeTaintsPolicy indicates how we will treat node taints when calculating pod topology spread skew. Options are: - Honor: nodes without taints, along with tainted nodes for which the incoming pod has a toleration, are included. - Ignore: node taints are ignored. All nodes are included.\n\nIf this value is nil, the behavior is equivalent to the Ignore policy. This is a beta-level feature default enabled by the NodeInclusionPolicyInPodTopologySpread feature flag.";
          type = (types.nullOr types.str);
        };
        "topologyKey" = mkOption {
          description = "TopologyKey is the key of node labels. Nodes that have a label with this key and identical values are considered to be in the same topology. We consider each <key, value> as a \"bucket\", and try to put balanced number of pods into each bucket. We define a domain as a particular instance of a topology. Also, we define an eligible domain as a domain whose nodes meet the requirements of nodeAffinityPolicy and nodeTaintsPolicy. e.g. If TopologyKey is \"kubernetes.io/hostname\", each Node is a domain of that topology. And, if TopologyKey is \"topology.kubernetes.io/zone\", each zone is a domain of that topology. It's a required field.";
          type = types.str;
        };
        "whenUnsatisfiable" = mkOption {
          description = "WhenUnsatisfiable indicates how to deal with a pod if it doesn't satisfy the spread constraint. - DoNotSchedule (default) tells the scheduler not to schedule it. - ScheduleAnyway tells the scheduler to schedule the pod in any location,\n  but giving higher precedence to topologies that would help reduce the\n  skew.\nA constraint is considered \"Unsatisfiable\" for an incoming pod if and only if every possible node assignment for that pod would violate \"MaxSkew\" on some topology. For example, in a 3-zone cluster, MaxSkew is set to 1, and pods with the same labelSelector spread as 3/1/1: | zone1 | zone2 | zone3 | | P P P |   P   |   P   | If WhenUnsatisfiable is set to DoNotSchedule, incoming pod can only be scheduled to zone2(zone3) to become 3/2/1(3/1/2) as ActualSkew(2-1) on zone2(zone3) satisfies MaxSkew(1). In other words, the cluster can still be imbalanced, but scheduler won't make it *more* imbalanced. It's a required field.\n\n";
          type = types.str;
        };
      };


      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "minDomains" = mkOverride 1002 null;
        "nodeAffinityPolicy" = mkOverride 1002 null;
        "nodeTaintsPolicy" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.TypedLocalObjectReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. If APIGroup is not specified, the specified Kind must be in the core API group. For any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.TypedObjectReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. If APIGroup is not specified, the specified Kind must be in the core API group. For any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of resource being referenced Note that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details. (Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.Volume" = {

      options = {
        "awsElasticBlockStore" = mkOption {
          description = "awsElasticBlockStore represents an AWS Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AWSElasticBlockStoreVolumeSource"));
        };
        "azureDisk" = mkOption {
          description = "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AzureDiskVolumeSource"));
        };
        "azureFile" = mkOption {
          description = "azureFile represents an Azure File Service mount on the host and bind mount to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.AzureFileVolumeSource"));
        };
        "cephfs" = mkOption {
          description = "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CephFSVolumeSource"));
        };
        "cinder" = mkOption {
          description = "cinder represents a cinder volume attached and mounted on kubelets host machine. More info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CinderVolumeSource"));
        };
        "configMap" = mkOption {
          description = "configMap represents a configMap that should populate this volume";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ConfigMapVolumeSource"));
        };
        "csi" = mkOption {
          description = "csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers (Beta feature).";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.CSIVolumeSource"));
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI represents downward API about the pod that should populate this volume";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.DownwardAPIVolumeSource"));
        };
        "emptyDir" = mkOption {
          description = "emptyDir represents a temporary directory that shares a pod's lifetime. More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EmptyDirVolumeSource"));
        };
        "ephemeral" = mkOption {
          description = "ephemeral represents a volume that is handled by a cluster storage driver. The volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts, and deleted when the pod is removed.\n\nUse this if: a) the volume is only needed while the pod runs, b) features of normal volumes like restoring from snapshot or capacity\n   tracking are needed,\nc) the storage driver is specified through a storage class, and d) the storage driver supports dynamic volume provisioning through\n   a PersistentVolumeClaim (see EphemeralVolumeSource for more\n   information on the connection between this volume type\n   and PersistentVolumeClaim).\n\nUse PersistentVolumeClaim or one of the vendor-specific APIs for volumes that persist for longer than the lifecycle of an individual pod.\n\nUse CSI for light-weight local ephemeral volumes if the CSI driver is meant to be used that way - see the documentation of the driver for more information.\n\nA pod can use both types of ephemeral volumes and persistent volumes at the same time.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EphemeralVolumeSource"));
        };
        "fc" = mkOption {
          description = "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FCVolumeSource"));
        };
        "flexVolume" = mkOption {
          description = "flexVolume represents a generic volume resource that is provisioned/attached using an exec based plugin.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FlexVolumeSource"));
        };
        "flocker" = mkOption {
          description = "flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.FlockerVolumeSource"));
        };
        "gcePersistentDisk" = mkOption {
          description = "gcePersistentDisk represents a GCE Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GCEPersistentDiskVolumeSource"));
        };
        "gitRepo" = mkOption {
          description = "gitRepo represents a git repository at a particular revision. DEPRECATED: GitRepo is deprecated. To provision a container with a git repo, mount an EmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir into the Pod's container.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GitRepoVolumeSource"));
        };
        "glusterfs" = mkOption {
          description = "glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/glusterfs/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.GlusterfsVolumeSource"));
        };
        "hostPath" = mkOption {
          description = "hostPath represents a pre-existing file or directory on the host machine that is directly exposed to the container. This is generally used for system agents or other privileged things that are allowed to see the host machine. Most containers will NOT need this. More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.HostPathVolumeSource"));
        };
        "iscsi" = mkOption {
          description = "iscsi represents an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://examples.k8s.io/volumes/iscsi/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ISCSIVolumeSource"));
        };
        "name" = mkOption {
          description = "name of the volume. Must be a DNS_LABEL and unique within the pod. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NFSVolumeSource"));
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a PersistentVolumeClaim in the same namespace. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeClaimVolumeSource"));
        };
        "photonPersistentDisk" = mkOption {
          description = "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PhotonPersistentDiskVolumeSource"));
        };
        "portworxVolume" = mkOption {
          description = "portworxVolume represents a portworx volume attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PortworxVolumeSource"));
        };
        "projected" = mkOption {
          description = "projected items for all in one resources secrets, configmaps, and downward API";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ProjectedVolumeSource"));
        };
        "quobyte" = mkOption {
          description = "quobyte represents a Quobyte mount on the host that shares a pod's lifetime";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.QuobyteVolumeSource"));
        };
        "rbd" = mkOption {
          description = "rbd represents a Rados Block Device mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/rbd/README.md";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.RBDVolumeSource"));
        };
        "scaleIO" = mkOption {
          description = "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ScaleIOVolumeSource"));
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume. More info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretVolumeSource"));
        };
        "storageos" = mkOption {
          description = "storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.StorageOSVolumeSource"));
        };
        "vsphereVolume" = mkOption {
          description = "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.VsphereVirtualDiskVolumeSource"));
        };
      };


      config = {
        "awsElasticBlockStore" = mkOverride 1002 null;
        "azureDisk" = mkOverride 1002 null;
        "azureFile" = mkOverride 1002 null;
        "cephfs" = mkOverride 1002 null;
        "cinder" = mkOverride 1002 null;
        "configMap" = mkOverride 1002 null;
        "csi" = mkOverride 1002 null;
        "downwardAPI" = mkOverride 1002 null;
        "emptyDir" = mkOverride 1002 null;
        "ephemeral" = mkOverride 1002 null;
        "fc" = mkOverride 1002 null;
        "flexVolume" = mkOverride 1002 null;
        "flocker" = mkOverride 1002 null;
        "gcePersistentDisk" = mkOverride 1002 null;
        "gitRepo" = mkOverride 1002 null;
        "glusterfs" = mkOverride 1002 null;
        "hostPath" = mkOverride 1002 null;
        "iscsi" = mkOverride 1002 null;
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "photonPersistentDisk" = mkOverride 1002 null;
        "portworxVolume" = mkOverride 1002 null;
        "projected" = mkOverride 1002 null;
        "quobyte" = mkOverride 1002 null;
        "rbd" = mkOverride 1002 null;
        "scaleIO" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "storageos" = mkOverride 1002 null;
        "vsphereVolume" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.VolumeDevice" = {

      options = {
        "devicePath" = mkOption {
          description = "devicePath is the path inside of the container that the device will be mapped to.";
          type = types.str;
        };
        "name" = mkOption {
          description = "name must match the name of a persistentVolumeClaim in the pod";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.VolumeMount" = {

      options = {
        "mountPath" = mkOption {
          description = "Path within the container at which the volume should be mounted.  Must not contain ':'.";
          type = types.str;
        };
        "mountPropagation" = mkOption {
          description = "mountPropagation determines how mounts are propagated from the host to container and the other way around. When not set, MountPropagationNone is used. This field is beta in 1.10.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "This must match the Name of a Volume.";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "Mounted read-only if true, read-write otherwise (false or unspecified). Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "subPath" = mkOption {
          description = "Path within the volume from which the container's volume should be mounted. Defaults to \"\" (volume's root).";
          type = (types.nullOr types.str);
        };
        "subPathExpr" = mkOption {
          description = "Expanded path within the volume from which the container's volume should be mounted. Behaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment. Defaults to \"\" (volume's root). SubPathExpr and SubPath are mutually exclusive.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "mountPropagation" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "subPath" = mkOverride 1002 null;
        "subPathExpr" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.VolumeNodeAffinity" = {

      options = {
        "required" = mkOption {
          description = "required specifies hard node constraints that must be met.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSelector"));
        };
      };


      config = {
        "required" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.VolumeProjection" = {

      options = {
        "configMap" = mkOption {
          description = "configMap information about the configMap data to project";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ConfigMapProjection"));
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI information about the downwardAPI data to project";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.DownwardAPIProjection"));
        };
        "secret" = mkOption {
          description = "secret information about the secret data to project";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.SecretProjection"));
        };
        "serviceAccountToken" = mkOption {
          description = "serviceAccountToken is information about the serviceAccountToken data to project";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ServiceAccountTokenProjection"));
        };
      };


      config = {
        "configMap" = mkOverride 1002 null;
        "downwardAPI" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "serviceAccountToken" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.VsphereVirtualDiskVolumeSource" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "storagePolicyID" = mkOption {
          description = "storagePolicyID is the storage Policy Based Management (SPBM) profile ID associated with the StoragePolicyName.";
          type = (types.nullOr types.str);
        };
        "storagePolicyName" = mkOption {
          description = "storagePolicyName is the storage Policy Based Management (SPBM) profile name.";
          type = (types.nullOr types.str);
        };
        "volumePath" = mkOption {
          description = "volumePath is the path that identifies vSphere volume vmdk";
          type = types.str;
        };
      };


      config = {
        "fsType" = mkOverride 1002 null;
        "storagePolicyID" = mkOverride 1002 null;
        "storagePolicyName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.core.v1.WeightedPodAffinityTerm" = {

      options = {
        "podAffinityTerm" = mkOption {
          description = "Required. A pod affinity term, associated with the corresponding weight.";
          type = (submoduleOf "io.k8s.api.core.v1.PodAffinityTerm");
        };
        "weight" = mkOption {
          description = "weight associated with matching the corresponding podAffinityTerm, in the range 1-100.";
          type = types.int;
        };
      };


      config = { };

    };
    "io.k8s.api.core.v1.WindowsSecurityContextOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook (https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the GMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container. This field is alpha-level and will only be honored by components that enable the WindowsHostProcessContainers feature flag. Setting this field without the feature flag will result in errors when validating the Pod. All of a Pod's containers must have the same effective HostProcess value (it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).  In addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process. Defaults to the user specified in image metadata if unspecified. May also be set in PodSecurityContext. If set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "gmsaCredentialSpec" = mkOverride 1002 null;
        "gmsaCredentialSpecName" = mkOverride 1002 null;
        "hostProcess" = mkOverride 1002 null;
        "runAsUserName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.Endpoint" = {

      options = {
        "addresses" = mkOption {
          description = "addresses of this endpoint. The contents of this field are interpreted according to the corresponding EndpointSlice addressType field. Consumers must handle different types of addresses in the context of their own capabilities. This must contain at least one address but no more than 100. These are all assumed to be fungible and clients may choose to only use the first element. Refer to: https://issue.k8s.io/106267";
          type = (types.listOf types.str);
        };
        "conditions" = mkOption {
          description = "conditions contains information about the current status of the endpoint.";
          type = (types.nullOr (submoduleOf "io.k8s.api.discovery.v1.EndpointConditions"));
        };
        "deprecatedTopology" = mkOption {
          description = "deprecatedTopology contains topology information part of the v1beta1 API. This field is deprecated, and will be removed when the v1beta1 API is removed (no sooner than kubernetes v1.24).  While this field can hold values, it is not writable through the v1 API, and any attempts to write to it will be silently ignored. Topology information can be found in the zone and nodeName fields instead.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "hints" = mkOption {
          description = "hints contains information associated with how an endpoint should be consumed.";
          type = (types.nullOr (submoduleOf "io.k8s.api.discovery.v1.EndpointHints"));
        };
        "hostname" = mkOption {
          description = "hostname of this endpoint. This field may be used by consumers of endpoints to distinguish endpoints from each other (e.g. in DNS names). Multiple endpoints which use the same hostname should be considered fungible (e.g. multiple A values in DNS). Must be lowercase and pass DNS Label (RFC 1123) validation.";
          type = (types.nullOr types.str);
        };
        "nodeName" = mkOption {
          description = "nodeName represents the name of the Node hosting this endpoint. This can be used to determine endpoints local to a Node.";
          type = (types.nullOr types.str);
        };
        "targetRef" = mkOption {
          description = "targetRef is a reference to a Kubernetes object that represents this endpoint.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "zone" = mkOption {
          description = "zone is the name of the Zone this endpoint exists in.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "deprecatedTopology" = mkOverride 1002 null;
        "hints" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "nodeName" = mkOverride 1002 null;
        "targetRef" = mkOverride 1002 null;
        "zone" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.EndpointConditions" = {

      options = {
        "ready" = mkOption {
          description = "ready indicates that this endpoint is prepared to receive traffic, according to whatever system is managing the endpoint. A nil value indicates an unknown state. In most cases consumers should interpret this unknown state as ready. For compatibility reasons, ready should never be \"true\" for terminating endpoints.";
          type = (types.nullOr types.bool);
        };
        "serving" = mkOption {
          description = "serving is identical to ready except that it is set regardless of the terminating state of endpoints. This condition should be set to true for a ready endpoint that is terminating. If nil, consumers should defer to the ready condition.";
          type = (types.nullOr types.bool);
        };
        "terminating" = mkOption {
          description = "terminating indicates that this endpoint is terminating. A nil value indicates an unknown state. Consumers should interpret this unknown state to mean that the endpoint is not terminating.";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "ready" = mkOverride 1002 null;
        "serving" = mkOverride 1002 null;
        "terminating" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.EndpointHints" = {

      options = {
        "forZones" = mkOption {
          description = "forZones indicates the zone(s) this endpoint should be consumed by to enable topology aware routing.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.discovery.v1.ForZone")));
        };
      };


      config = {
        "forZones" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.EndpointPort" = {

      options = {
        "appProtocol" = mkOption {
          description = "The application protocol for this port. This field follows standard Kubernetes label syntax. Un-prefixed names are reserved for IANA standard service names (as per RFC-6335 and https://www.iana.org/assignments/service-names). Non-standard protocols should use prefixed names such as mycompany.com/my-custom-protocol.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of this port. All ports in an EndpointSlice must have a unique name. If the EndpointSlice is dervied from a Kubernetes service, this corresponds to the Service.ports[].name. Name must either be an empty string or pass DNS_LABEL validation: * must be no more than 63 characters long. * must consist of lower case alphanumeric characters or '-'. * must start and end with an alphanumeric character. Default is empty string.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "The port number of the endpoint. If this is not specified, ports are not restricted and must be interpreted in the context of the specific consumer.";
          type = (types.nullOr types.int);
        };
        "protocol" = mkOption {
          description = "The IP protocol for this port. Must be UDP, TCP, or SCTP. Default is TCP.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "appProtocol" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.EndpointSlice" = {

      options = {
        "addressType" = mkOption {
          description = "addressType specifies the type of address carried by this EndpointSlice. All addresses in this slice must be the same type. This field is immutable after creation. The following address types are currently supported: * IPv4: Represents an IPv4 Address. * IPv6: Represents an IPv6 Address. * FQDN: Represents a Fully Qualified Domain Name.\n\n";
          type = types.str;
        };
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "endpoints" = mkOption {
          description = "endpoints is a list of unique endpoints in this slice. Each slice may include a maximum of 1000 endpoints.";
          type = (types.listOf (submoduleOf "io.k8s.api.discovery.v1.Endpoint"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "ports" = mkOption {
          description = "ports specifies the list of network ports exposed by each endpoint in this slice. Each port must have a unique name. When ports is empty, it indicates that there are no defined ports. When a port is defined with a nil port value, it indicates \"all ports\". Each slice may include a maximum of 100 ports.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.discovery.v1.EndpointPort")));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.EndpointSliceList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "List of endpoint slices";
          type = (types.listOf (submoduleOf "io.k8s.api.discovery.v1.EndpointSlice"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.discovery.v1.ForZone" = {

      options = {
        "name" = mkOption {
          description = "name represents the name of the zone.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.events.v1.Event" = {

      options = {
        "action" = mkOption {
          description = "action is what action was taken/failed regarding to the regarding object. It is machine-readable. This field cannot be empty for new Events and it can have at most 128 characters.";
          type = (types.nullOr types.str);
        };
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "deprecatedCount" = mkOption {
          description = "deprecatedCount is the deprecated field assuring backward compatibility with core.v1 Event type.";
          type = (types.nullOr types.int);
        };
        "deprecatedFirstTimestamp" = mkOption {
          description = "deprecatedFirstTimestamp is the deprecated field assuring backward compatibility with core.v1 Event type.";
          type = (types.nullOr types.str);
        };
        "deprecatedLastTimestamp" = mkOption {
          description = "deprecatedLastTimestamp is the deprecated field assuring backward compatibility with core.v1 Event type.";
          type = (types.nullOr types.str);
        };
        "deprecatedSource" = mkOption {
          description = "deprecatedSource is the deprecated field assuring backward compatibility with core.v1 Event type.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.EventSource"));
        };
        "eventTime" = mkOption {
          description = "eventTime is the time when this Event was first observed. It is required.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "note" = mkOption {
          description = "note is a human-readable description of the status of this operation. Maximal length of the note is 1kB, but libraries should be prepared to handle values up to 64kB.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is why the action was taken. It is human-readable. This field cannot be empty for new Events and it can have at most 128 characters.";
          type = (types.nullOr types.str);
        };
        "regarding" = mkOption {
          description = "regarding contains the object this Event is about. In most cases it's an Object reporting controller implements, e.g. ReplicaSetController implements ReplicaSets and this event is emitted because it acts on some changes in a ReplicaSet object.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "related" = mkOption {
          description = "related is the optional secondary object for more complex actions. E.g. when regarding object triggers a creation or deletion of related object.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.ObjectReference"));
        };
        "reportingController" = mkOption {
          description = "reportingController is the name of the controller that emitted this Event, e.g. `kubernetes.io/kubelet`. This field cannot be empty for new Events.";
          type = (types.nullOr types.str);
        };
        "reportingInstance" = mkOption {
          description = "reportingInstance is the ID of the controller instance, e.g. `kubelet-xyzf`. This field cannot be empty for new Events and it can have at most 128 characters.";
          type = (types.nullOr types.str);
        };
        "series" = mkOption {
          description = "series is data about the Event series this event represents or nil if it's a singleton Event.";
          type = (types.nullOr (submoduleOf "io.k8s.api.events.v1.EventSeries"));
        };
        "type" = mkOption {
          description = "type is the type of this event (Normal, Warning), new types could be added in the future. It is machine-readable. This field cannot be empty for new Events.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "action" = mkOverride 1002 null;
        "apiVersion" = mkOverride 1002 null;
        "deprecatedCount" = mkOverride 1002 null;
        "deprecatedFirstTimestamp" = mkOverride 1002 null;
        "deprecatedLastTimestamp" = mkOverride 1002 null;
        "deprecatedSource" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "note" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "regarding" = mkOverride 1002 null;
        "related" = mkOverride 1002 null;
        "reportingController" = mkOverride 1002 null;
        "reportingInstance" = mkOverride 1002 null;
        "series" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.events.v1.EventList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is a list of schema objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.events.v1.Event"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.events.v1.EventSeries" = {

      options = {
        "count" = mkOption {
          description = "count is the number of occurrences in this series up to the last heartbeat time.";
          type = types.int;
        };
        "lastObservedTime" = mkOption {
          description = "lastObservedTime is the time when last Event from the series was seen before last heartbeat.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowDistinguisherMethod" = {

      options = {
        "type" = mkOption {
          description = "`type` is the type of flow distinguisher method The supported types are \"ByUser\" and \"ByNamespace\". Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowSchema" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "`spec` is the specification of the desired behavior of a FlowSchema. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.FlowSchemaSpec"));
        };
        "status" = mkOption {
          description = "`status` is the current status of a FlowSchema. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.FlowSchemaStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowSchemaCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "`lastTransitionTime` is the last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "`message` is a human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "`reason` is a unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "`status` is the status of the condition. Can be True, False, Unknown. Required.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "`type` is the type of the condition. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowSchemaList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "`items` is a list of FlowSchemas.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.FlowSchema"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowSchemaSpec" = {

      options = {
        "distinguisherMethod" = mkOption {
          description = "`distinguisherMethod` defines how to compute the flow distinguisher for requests that match this schema. `nil` specifies that the distinguisher is disabled and thus will always be the empty string.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.FlowDistinguisherMethod"));
        };
        "matchingPrecedence" = mkOption {
          description = "`matchingPrecedence` is used to choose among the FlowSchemas that match a given request. The chosen FlowSchema is among those with the numerically lowest (which we take to be logically highest) MatchingPrecedence.  Each MatchingPrecedence value must be ranged in [1,10000]. Note that if the precedence is not specified, it will be set to 1000 as default.";
          type = (types.nullOr types.int);
        };
        "priorityLevelConfiguration" = mkOption {
          description = "`priorityLevelConfiguration` should reference a PriorityLevelConfiguration in the cluster. If the reference cannot be resolved, the FlowSchema will be ignored and marked as invalid in its status. Required.";
          type = (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationReference");
        };
        "rules" = mkOption {
          description = "`rules` describes which requests will match this flow schema. This FlowSchema matches a request if and only if at least one member of rules matches the request. if it is an empty slice, there will be no requests matching the FlowSchema.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PolicyRulesWithSubjects")));
        };
      };


      config = {
        "distinguisherMethod" = mkOverride 1002 null;
        "matchingPrecedence" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.FlowSchemaStatus" = {

      options = {
        "conditions" = mkOption {
          description = "`conditions` is a list of the current states of FlowSchema.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.FlowSchemaCondition")));
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.GroupSubject" = {

      options = {
        "name" = mkOption {
          description = "name is the user group that matches, or \"*\" to match all user groups. See https://github.com/kubernetes/apiserver/blob/master/pkg/authentication/user/user.go for some well-known group names. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.LimitResponse" = {

      options = {
        "queuing" = mkOption {
          description = "`queuing` holds the configuration parameters for queuing. This field may be non-empty only if `type` is `\"Queue\"`.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.QueuingConfiguration"));
        };
        "type" = mkOption {
          description = "`type` is \"Queue\" or \"Reject\". \"Queue\" means that requests that can not be executed upon arrival are held in a queue until they can be executed or a queuing limit is reached. \"Reject\" means that requests that can not be executed upon arrival are rejected. Required.";
          type = types.str;
        };
      };


      config = {
        "queuing" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.LimitedPriorityLevelConfiguration" = {

      options = {
        "assuredConcurrencyShares" = mkOption {
          description = "`assuredConcurrencyShares` (ACS) configures the execution limit, which is a limit on the number of requests of this priority level that may be exeucting at a given time.  ACS must be a positive number. The server's concurrency limit (SCL) is divided among the concurrency-controlled priority levels in proportion to their assured concurrency shares. This produces the assured concurrency value (ACV) --- the number of requests that may be executing at a time --- for each such priority level:\n\n            ACV(l) = ceil( SCL * ACS(l) / ( sum[priority levels k] ACS(k) ) )\n\nbigger numbers of ACS mean more reserved concurrent requests (at the expense of every other PL). This field has a default value of 30.";
          type = (types.nullOr types.int);
        };
        "borrowingLimitPercent" = mkOption {
          description = "`borrowingLimitPercent`, if present, configures a limit on how many seats this priority level can borrow from other priority levels. The limit is known as this level's BorrowingConcurrencyLimit (BorrowingCL) and is a limit on the total number of seats that this level may borrow at any one time. This field holds the ratio of that limit to the level's nominal concurrency limit. When this field is non-nil, it must hold a non-negative integer and the limit is calculated as follows.\n\nBorrowingCL(i) = round( NominalCL(i) * borrowingLimitPercent(i)/100.0 )\n\nThe value of this field can be more than 100, implying that this priority level can borrow a number of seats that is greater than its own nominal concurrency limit (NominalCL). When this field is left `nil`, the limit is effectively infinite.";
          type = (types.nullOr types.int);
        };
        "lendablePercent" = mkOption {
          description = "`lendablePercent` prescribes the fraction of the level's NominalCL that can be borrowed by other priority levels. The value of this field must be between 0 and 100, inclusive, and it defaults to 0. The number of seats that other levels can borrow from this level, known as this level's LendableConcurrencyLimit (LendableCL), is defined as follows.\n\nLendableCL(i) = round( NominalCL(i) * lendablePercent(i)/100.0 )";
          type = (types.nullOr types.int);
        };
        "limitResponse" = mkOption {
          description = "`limitResponse` indicates what to do with requests that can not be executed right now";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.LimitResponse"));
        };
      };


      config = {
        "assuredConcurrencyShares" = mkOverride 1002 null;
        "borrowingLimitPercent" = mkOverride 1002 null;
        "lendablePercent" = mkOverride 1002 null;
        "limitResponse" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.NonResourcePolicyRule" = {

      options = {
        "nonResourceURLs" = mkOption {
          description = "`nonResourceURLs` is a set of url prefixes that a user should have access to and may not be empty. For example:\n  - \"/healthz\" is legal\n  - \"/hea*\" is illegal\n  - \"/hea\" is legal but matches nothing\n  - \"/hea/*\" also matches nothing\n  - \"/healthz/*\" matches all per-component health checks.\n\"*\" matches all non-resource urls. if it is present, it must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "verbs" = mkOption {
          description = "`verbs` is a list of matching verbs and may not be empty. \"*\" matches all verbs. If it is present, it must be the only entry. Required.";
          type = (types.listOf types.str);
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.PolicyRulesWithSubjects" = {

      options = {
        "nonResourceRules" = mkOption {
          description = "`nonResourceRules` is a list of NonResourcePolicyRules that identify matching requests according to their verb and the target non-resource URL.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.NonResourcePolicyRule")));
        };
        "resourceRules" = mkOption {
          description = "`resourceRules` is a slice of ResourcePolicyRules that identify matching requests according to their verb and the target resource. At least one of `resourceRules` and `nonResourceRules` has to be non-empty.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.ResourcePolicyRule")));
        };
        "subjects" = mkOption {
          description = "subjects is the list of normal user, serviceaccount, or group that this rule cares about. There must be at least one member in this slice. A slice that includes both the system:authenticated and system:unauthenticated user groups matches every request. Required.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.Subject"));
        };
      };


      config = {
        "nonResourceRules" = mkOverride 1002 null;
        "resourceRules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfiguration" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "`spec` is the specification of the desired behavior of a \"request-priority\". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationSpec"));
        };
        "status" = mkOption {
          description = "`status` is the current status of a \"request-priority\". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "`lastTransitionTime` is the last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "`message` is a human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "`reason` is a unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "`status` is the status of the condition. Can be True, False, Unknown. Required.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "`type` is the type of the condition. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "`items` is a list of request-priorities.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfiguration"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationReference" = {

      options = {
        "name" = mkOption {
          description = "`name` is the name of the priority level configuration being referenced Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationSpec" = {

      options = {
        "limited" = mkOption {
          description = "`limited` specifies how requests are handled for a Limited priority level. This field must be non-empty if and only if `type` is `\"Limited\"`.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.LimitedPriorityLevelConfiguration"));
        };
        "type" = mkOption {
          description = "`type` indicates whether this priority level is subject to limitation on request execution.  A value of `\"Exempt\"` means that requests of this priority level are not subject to a limit (and thus are never queued) and do not detract from the capacity made available to other priority levels.  A value of `\"Limited\"` means that (a) requests of this priority level _are_ subject to limits and (b) some of the server's limited capacity is made available exclusively to this priority level. Required.";
          type = types.str;
        };
      };


      config = {
        "limited" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationStatus" = {

      options = {
        "conditions" = mkOption {
          description = "`conditions` is the current state of \"request-priority\".";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfigurationCondition")));
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.QueuingConfiguration" = {

      options = {
        "handSize" = mkOption {
          description = "`handSize` is a small positive number that configures the shuffle sharding of requests into queues.  When enqueuing a request at this priority level the request's flow identifier (a string pair) is hashed and the hash value is used to shuffle the list of queues and deal a hand of the size specified here.  The request is put into one of the shortest queues in that hand. `handSize` must be no larger than `queues`, and should be significantly smaller (so that a few heavy flows do not saturate most of the queues).  See the user-facing documentation for more extensive guidance on setting this field.  This field has a default value of 8.";
          type = (types.nullOr types.int);
        };
        "queueLengthLimit" = mkOption {
          description = "`queueLengthLimit` is the maximum number of requests allowed to be waiting in a given queue of this priority level at a time; excess requests are rejected.  This value must be positive.  If not specified, it will be defaulted to 50.";
          type = (types.nullOr types.int);
        };
        "queues" = mkOption {
          description = "`queues` is the number of queues for this priority level. The queues exist independently at each apiserver. The value must be positive.  Setting it to 1 effectively precludes shufflesharding and thus makes the distinguisher method of associated flow schemas irrelevant.  This field has a default value of 64.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "handSize" = mkOverride 1002 null;
        "queueLengthLimit" = mkOverride 1002 null;
        "queues" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.ResourcePolicyRule" = {

      options = {
        "apiGroups" = mkOption {
          description = "`apiGroups` is a list of matching API groups and may not be empty. \"*\" matches all API groups and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "clusterScope" = mkOption {
          description = "`clusterScope` indicates whether to match requests that do not specify a namespace (which happens either because the resource is not namespaced or the request targets all namespaces). If this field is omitted or false then the `namespaces` field must contain a non-empty list.";
          type = (types.nullOr types.bool);
        };
        "namespaces" = mkOption {
          description = "`namespaces` is a list of target namespaces that restricts matches.  A request that specifies a target namespace matches only if either (a) this list contains that target namespace or (b) this list contains \"*\".  Note that \"*\" matches any specified namespace but does not match a request that _does not specify_ a namespace (see the `clusterScope` field for that). This list may be empty, but only if `clusterScope` is true.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "`resources` is a list of matching resources (i.e., lowercase and plural) with, if desired, subresource.  For example, [ \"services\", \"nodes/status\" ].  This list may not be empty. \"*\" matches all resources and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "verbs" = mkOption {
          description = "`verbs` is a list of matching verbs and may not be empty. \"*\" matches all verbs and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "clusterScope" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.ServiceAccountSubject" = {

      options = {
        "name" = mkOption {
          description = "`name` is the name of matching ServiceAccount objects, or \"*\" to match regardless of name. Required.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "`namespace` is the namespace of matching ServiceAccount objects. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta2.Subject" = {

      options = {
        "group" = mkOption {
          description = "`group` matches based on user group name.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.GroupSubject"));
        };
        "kind" = mkOption {
          description = "`kind` indicates which one of the other fields is non-empty. Required";
          type = types.str;
        };
        "serviceAccount" = mkOption {
          description = "`serviceAccount` matches ServiceAccounts.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.ServiceAccountSubject"));
        };
        "user" = mkOption {
          description = "`user` matches based on username.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta2.UserSubject"));
        };
      };


      config = {
        "group" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta2.UserSubject" = {

      options = {
        "name" = mkOption {
          description = "`name` is the username that matches, or \"*\" to match all usernames. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowDistinguisherMethod" = {

      options = {
        "type" = mkOption {
          description = "`type` is the type of flow distinguisher method The supported types are \"ByUser\" and \"ByNamespace\". Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowSchema" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "`spec` is the specification of the desired behavior of a FlowSchema. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.FlowSchemaSpec"));
        };
        "status" = mkOption {
          description = "`status` is the current status of a FlowSchema. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.FlowSchemaStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowSchemaCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "`lastTransitionTime` is the last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "`message` is a human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "`reason` is a unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "`status` is the status of the condition. Can be True, False, Unknown. Required.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "`type` is the type of the condition. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowSchemaList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "`items` is a list of FlowSchemas.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.FlowSchema"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowSchemaSpec" = {

      options = {
        "distinguisherMethod" = mkOption {
          description = "`distinguisherMethod` defines how to compute the flow distinguisher for requests that match this schema. `nil` specifies that the distinguisher is disabled and thus will always be the empty string.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.FlowDistinguisherMethod"));
        };
        "matchingPrecedence" = mkOption {
          description = "`matchingPrecedence` is used to choose among the FlowSchemas that match a given request. The chosen FlowSchema is among those with the numerically lowest (which we take to be logically highest) MatchingPrecedence.  Each MatchingPrecedence value must be ranged in [1,10000]. Note that if the precedence is not specified, it will be set to 1000 as default.";
          type = (types.nullOr types.int);
        };
        "priorityLevelConfiguration" = mkOption {
          description = "`priorityLevelConfiguration` should reference a PriorityLevelConfiguration in the cluster. If the reference cannot be resolved, the FlowSchema will be ignored and marked as invalid in its status. Required.";
          type = (submoduleOf "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationReference");
        };
        "rules" = mkOption {
          description = "`rules` describes which requests will match this flow schema. This FlowSchema matches a request if and only if at least one member of rules matches the request. if it is an empty slice, there will be no requests matching the FlowSchema.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.PolicyRulesWithSubjects")));
        };
      };


      config = {
        "distinguisherMethod" = mkOverride 1002 null;
        "matchingPrecedence" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.FlowSchemaStatus" = {

      options = {
        "conditions" = mkOption {
          description = "`conditions` is a list of the current states of FlowSchema.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.flowcontrol.v1beta3.FlowSchemaCondition" "type"));
          apply = attrsToList;
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.GroupSubject" = {

      options = {
        "name" = mkOption {
          description = "name is the user group that matches, or \"*\" to match all user groups. See https://github.com/kubernetes/apiserver/blob/master/pkg/authentication/user/user.go for some well-known group names. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.LimitResponse" = {

      options = {
        "queuing" = mkOption {
          description = "`queuing` holds the configuration parameters for queuing. This field may be non-empty only if `type` is `\"Queue\"`.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.QueuingConfiguration"));
        };
        "type" = mkOption {
          description = "`type` is \"Queue\" or \"Reject\". \"Queue\" means that requests that can not be executed upon arrival are held in a queue until they can be executed or a queuing limit is reached. \"Reject\" means that requests that can not be executed upon arrival are rejected. Required.";
          type = types.str;
        };
      };


      config = {
        "queuing" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.LimitedPriorityLevelConfiguration" = {

      options = {
        "borrowingLimitPercent" = mkOption {
          description = "`borrowingLimitPercent`, if present, configures a limit on how many seats this priority level can borrow from other priority levels. The limit is known as this level's BorrowingConcurrencyLimit (BorrowingCL) and is a limit on the total number of seats that this level may borrow at any one time. This field holds the ratio of that limit to the level's nominal concurrency limit. When this field is non-nil, it must hold a non-negative integer and the limit is calculated as follows.\n\nBorrowingCL(i) = round( NominalCL(i) * borrowingLimitPercent(i)/100.0 )\n\nThe value of this field can be more than 100, implying that this priority level can borrow a number of seats that is greater than its own nominal concurrency limit (NominalCL). When this field is left `nil`, the limit is effectively infinite.";
          type = (types.nullOr types.int);
        };
        "lendablePercent" = mkOption {
          description = "`lendablePercent` prescribes the fraction of the level's NominalCL that can be borrowed by other priority levels. The value of this field must be between 0 and 100, inclusive, and it defaults to 0. The number of seats that other levels can borrow from this level, known as this level's LendableConcurrencyLimit (LendableCL), is defined as follows.\n\nLendableCL(i) = round( NominalCL(i) * lendablePercent(i)/100.0 )";
          type = (types.nullOr types.int);
        };
        "limitResponse" = mkOption {
          description = "`limitResponse` indicates what to do with requests that can not be executed right now";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.LimitResponse"));
        };
        "nominalConcurrencyShares" = mkOption {
          description = "`nominalConcurrencyShares` (NCS) contributes to the computation of the NominalConcurrencyLimit (NominalCL) of this level. This is the number of execution seats available at this priority level. This is used both for requests dispatched from this priority level as well as requests dispatched from other priority levels borrowing seats from this level. The server's concurrency limit (ServerCL) is divided among the Limited priority levels in proportion to their NCS values:\n\nNominalCL(i)  = ceil( ServerCL * NCS(i) / sum_ncs ) sum_ncs = sum[limited priority level k] NCS(k)\n\nBigger numbers mean a larger nominal concurrency limit, at the expense of every other Limited priority level. This field has a default value of 30.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "borrowingLimitPercent" = mkOverride 1002 null;
        "lendablePercent" = mkOverride 1002 null;
        "limitResponse" = mkOverride 1002 null;
        "nominalConcurrencyShares" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.NonResourcePolicyRule" = {

      options = {
        "nonResourceURLs" = mkOption {
          description = "`nonResourceURLs` is a set of url prefixes that a user should have access to and may not be empty. For example:\n  - \"/healthz\" is legal\n  - \"/hea*\" is illegal\n  - \"/hea\" is legal but matches nothing\n  - \"/hea/*\" also matches nothing\n  - \"/healthz/*\" matches all per-component health checks.\n\"*\" matches all non-resource urls. if it is present, it must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "verbs" = mkOption {
          description = "`verbs` is a list of matching verbs and may not be empty. \"*\" matches all verbs. If it is present, it must be the only entry. Required.";
          type = (types.listOf types.str);
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.PolicyRulesWithSubjects" = {

      options = {
        "nonResourceRules" = mkOption {
          description = "`nonResourceRules` is a list of NonResourcePolicyRules that identify matching requests according to their verb and the target non-resource URL.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.NonResourcePolicyRule")));
        };
        "resourceRules" = mkOption {
          description = "`resourceRules` is a slice of ResourcePolicyRules that identify matching requests according to their verb and the target resource. At least one of `resourceRules` and `nonResourceRules` has to be non-empty.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.ResourcePolicyRule")));
        };
        "subjects" = mkOption {
          description = "subjects is the list of normal user, serviceaccount, or group that this rule cares about. There must be at least one member in this slice. A slice that includes both the system:authenticated and system:unauthenticated user groups matches every request. Required.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.Subject"));
        };
      };


      config = {
        "nonResourceRules" = mkOverride 1002 null;
        "resourceRules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfiguration" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "`spec` is the specification of the desired behavior of a \"request-priority\". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationSpec"));
        };
        "status" = mkOption {
          description = "`status` is the current status of a \"request-priority\". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "`lastTransitionTime` is the last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "`message` is a human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "`reason` is a unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "`status` is the status of the condition. Can be True, False, Unknown. Required.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "`type` is the type of the condition. Required.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "`items` is a list of request-priorities.";
          type = (types.listOf (submoduleOf "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfiguration"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "`metadata` is the standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationReference" = {

      options = {
        "name" = mkOption {
          description = "`name` is the name of the priority level configuration being referenced Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationSpec" = {

      options = {
        "limited" = mkOption {
          description = "`limited` specifies how requests are handled for a Limited priority level. This field must be non-empty if and only if `type` is `\"Limited\"`.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.LimitedPriorityLevelConfiguration"));
        };
        "type" = mkOption {
          description = "`type` indicates whether this priority level is subject to limitation on request execution.  A value of `\"Exempt\"` means that requests of this priority level are not subject to a limit (and thus are never queued) and do not detract from the capacity made available to other priority levels.  A value of `\"Limited\"` means that (a) requests of this priority level _are_ subject to limits and (b) some of the server's limited capacity is made available exclusively to this priority level. Required.";
          type = types.str;
        };
      };


      config = {
        "limited" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationStatus" = {

      options = {
        "conditions" = mkOption {
          description = "`conditions` is the current state of \"request-priority\".";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfigurationCondition" "type"));
          apply = attrsToList;
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.QueuingConfiguration" = {

      options = {
        "handSize" = mkOption {
          description = "`handSize` is a small positive number that configures the shuffle sharding of requests into queues.  When enqueuing a request at this priority level the request's flow identifier (a string pair) is hashed and the hash value is used to shuffle the list of queues and deal a hand of the size specified here.  The request is put into one of the shortest queues in that hand. `handSize` must be no larger than `queues`, and should be significantly smaller (so that a few heavy flows do not saturate most of the queues).  See the user-facing documentation for more extensive guidance on setting this field.  This field has a default value of 8.";
          type = (types.nullOr types.int);
        };
        "queueLengthLimit" = mkOption {
          description = "`queueLengthLimit` is the maximum number of requests allowed to be waiting in a given queue of this priority level at a time; excess requests are rejected.  This value must be positive.  If not specified, it will be defaulted to 50.";
          type = (types.nullOr types.int);
        };
        "queues" = mkOption {
          description = "`queues` is the number of queues for this priority level. The queues exist independently at each apiserver. The value must be positive.  Setting it to 1 effectively precludes shufflesharding and thus makes the distinguisher method of associated flow schemas irrelevant.  This field has a default value of 64.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "handSize" = mkOverride 1002 null;
        "queueLengthLimit" = mkOverride 1002 null;
        "queues" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.ResourcePolicyRule" = {

      options = {
        "apiGroups" = mkOption {
          description = "`apiGroups` is a list of matching API groups and may not be empty. \"*\" matches all API groups and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "clusterScope" = mkOption {
          description = "`clusterScope` indicates whether to match requests that do not specify a namespace (which happens either because the resource is not namespaced or the request targets all namespaces). If this field is omitted or false then the `namespaces` field must contain a non-empty list.";
          type = (types.nullOr types.bool);
        };
        "namespaces" = mkOption {
          description = "`namespaces` is a list of target namespaces that restricts matches.  A request that specifies a target namespace matches only if either (a) this list contains that target namespace or (b) this list contains \"*\".  Note that \"*\" matches any specified namespace but does not match a request that _does not specify_ a namespace (see the `clusterScope` field for that). This list may be empty, but only if `clusterScope` is true.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "`resources` is a list of matching resources (i.e., lowercase and plural) with, if desired, subresource.  For example, [ \"services\", \"nodes/status\" ].  This list may not be empty. \"*\" matches all resources and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
        "verbs" = mkOption {
          description = "`verbs` is a list of matching verbs and may not be empty. \"*\" matches all verbs and, if present, must be the only entry. Required.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "clusterScope" = mkOverride 1002 null;
        "namespaces" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.ServiceAccountSubject" = {

      options = {
        "name" = mkOption {
          description = "`name` is the name of matching ServiceAccount objects, or \"*\" to match regardless of name. Required.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "`namespace` is the namespace of matching ServiceAccount objects. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.flowcontrol.v1beta3.Subject" = {

      options = {
        "group" = mkOption {
          description = "`group` matches based on user group name.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.GroupSubject"));
        };
        "kind" = mkOption {
          description = "`kind` indicates which one of the other fields is non-empty. Required";
          type = types.str;
        };
        "serviceAccount" = mkOption {
          description = "`serviceAccount` matches ServiceAccounts.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.ServiceAccountSubject"));
        };
        "user" = mkOption {
          description = "`user` matches based on username.";
          type = (types.nullOr (submoduleOf "io.k8s.api.flowcontrol.v1beta3.UserSubject"));
        };
      };


      config = {
        "group" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.flowcontrol.v1beta3.UserSubject" = {

      options = {
        "name" = mkOption {
          description = "`name` is the username that matches, or \"*\" to match all usernames. Required.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.networking.v1.HTTPIngressPath" = {

      options = {
        "backend" = mkOption {
          description = "Backend defines the referenced service endpoint to which the traffic will be forwarded to.";
          type = (submoduleOf "io.k8s.api.networking.v1.IngressBackend");
        };
        "path" = mkOption {
          description = "Path is matched against the path of an incoming request. Currently it can contain characters disallowed from the conventional \"path\" part of a URL as defined by RFC 3986. Paths must begin with a '/' and must be present when using PathType with value \"Exact\" or \"Prefix\".";
          type = (types.nullOr types.str);
        };
        "pathType" = mkOption {
          description = "PathType determines the interpretation of the Path matching. PathType can be one of the following values: * Exact: Matches the URL path exactly. * Prefix: Matches based on a URL path prefix split by '/'. Matching is\n  done on a path element by element basis. A path element refers is the\n  list of labels in the path split by the '/' separator. A request is a\n  match for path p if every p is an element-wise prefix of p of the\n  request path. Note that if the last element of the path is a substring\n  of the last element in request path, it is not a match (e.g. /foo/bar\n  matches /foo/bar/baz, but does not match /foo/barbaz).\n* ImplementationSpecific: Interpretation of the Path matching is up to\n  the IngressClass. Implementations can treat this as a separate PathType\n  or treat it identically to Prefix or Exact path types.\nImplementations are required to support all path types.";
          type = types.str;
        };
      };


      config = {
        "path" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.HTTPIngressRuleValue" = {

      options = {
        "paths" = mkOption {
          description = "A collection of paths that map requests to backends.";
          type = (types.listOf (submoduleOf "io.k8s.api.networking.v1.HTTPIngressPath"));
        };
      };


      config = { };

    };
    "io.k8s.api.networking.v1.IPBlock" = {

      options = {
        "cidr" = mkOption {
          description = "CIDR is a string representing the IP Block Valid examples are \"192.168.1.0/24\" or \"2001:db8::/64\"";
          type = types.str;
        };
        "except" = mkOption {
          description = "Except is a slice of CIDRs that should not be included within an IP Block Valid examples are \"192.168.1.0/24\" or \"2001:db8::/64\" Except values will be rejected if they are outside the CIDR range";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "except" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.Ingress" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec is the desired state of the Ingress. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressSpec"));
        };
        "status" = mkOption {
          description = "Status is the current state of the Ingress. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressBackend" = {

      options = {
        "resource" = mkOption {
          description = "Resource is an ObjectRef to another Kubernetes resource in the namespace of the Ingress object. If resource is specified, a service.Name and service.Port must not be specified. This is a mutually exclusive setting with \"Service\".";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.TypedLocalObjectReference"));
        };
        "service" = mkOption {
          description = "Service references a Service as a Backend. This is a mutually exclusive setting with \"Resource\".";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressServiceBackend"));
        };
      };


      config = {
        "resource" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec is the desired state of the IngressClass. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressClassSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressClassList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of IngressClasses.";
          type = (types.listOf (submoduleOf "io.k8s.api.networking.v1.IngressClass"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressClassParametersReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. If APIGroup is not specified, the specified Kind must be in the core API group. For any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the resource being referenced. This field is required when scope is set to \"Namespace\" and must be unset when scope is set to \"Cluster\".";
          type = (types.nullOr types.str);
        };
        "scope" = mkOption {
          description = "Scope represents if this refers to a cluster or namespace scoped resource. This may be set to \"Cluster\" (default) or \"Namespace\".";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "scope" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressClassSpec" = {

      options = {
        "controller" = mkOption {
          description = "Controller refers to the name of the controller that should handle this class. This allows for different \"flavors\" that are controlled by the same controller. For example, you may have different Parameters for the same implementing controller. This should be specified as a domain-prefixed path no more than 250 characters in length, e.g. \"acme.io/ingress-controller\". This field is immutable.";
          type = (types.nullOr types.str);
        };
        "parameters" = mkOption {
          description = "Parameters is a link to a custom resource containing additional configuration for the controller. This is optional if the controller does not require extra parameters.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressClassParametersReference"));
        };
      };


      config = {
        "controller" = mkOverride 1002 null;
        "parameters" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of Ingress.";
          type = (types.listOf (submoduleOf "io.k8s.api.networking.v1.Ingress"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressLoadBalancerIngress" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is set for load-balancer ingress points that are DNS based.";
          type = (types.nullOr types.str);
        };
        "ip" = mkOption {
          description = "IP is set for load-balancer ingress points that are IP based.";
          type = (types.nullOr types.str);
        };
        "ports" = mkOption {
          description = "Ports provides information about the ports exposed by this LoadBalancer.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.IngressPortStatus")));
        };
      };


      config = {
        "hostname" = mkOverride 1002 null;
        "ip" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressLoadBalancerStatus" = {

      options = {
        "ingress" = mkOption {
          description = "Ingress is a list containing ingress points for the load-balancer.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.IngressLoadBalancerIngress")));
        };
      };


      config = {
        "ingress" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressPortStatus" = {

      options = {
        "error" = mkOption {
          description = "Error is to record the problem with the service port The format of the error shall comply with the following rules: - built-in error values shall be specified in this file and those shall use\n  CamelCase names\n- cloud provider specific error values must have names that comply with the\n  format foo.example.com/CamelCase.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "Port is the port number of the ingress port.";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "Protocol is the protocol of the ingress port. The supported values are: \"TCP\", \"UDP\", \"SCTP\"\n\n";
          type = types.str;
        };
      };


      config = {
        "error" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressRule" = {

      options = {
        "host" = mkOption {
          description = "Host is the fully qualified domain name of a network host, as defined by RFC 3986. Note the following deviations from the \"host\" part of the URI as defined in RFC 3986: 1. IPs are not allowed. Currently an IngressRuleValue can only apply to\n   the IP in the Spec of the parent Ingress.\n2. The `:` delimiter is not respected because ports are not allowed.\n\t  Currently the port of an Ingress is implicitly :80 for http and\n\t  :443 for https.\nBoth these may change in the future. Incoming requests are matched against the host before the IngressRuleValue. If the host is unspecified, the Ingress routes all traffic based on the specified IngressRuleValue.\n\nHost can be \"precise\" which is a domain name without the terminating dot of a network host (e.g. \"foo.bar.com\") or \"wildcard\", which is a domain name prefixed with a single wildcard label (e.g. \"*.foo.com\"). The wildcard character '*' must appear by itself as the first DNS label and matches only a single label. You cannot have a wildcard label by itself (e.g. Host == \"*\"). Requests will be matched against the Host field in the following way: 1. If Host is precise, the request matches this rule if the http host header is equal to Host. 2. If Host is a wildcard, then the request matches this rule if the http host header is to equal to the suffix (removing the first label) of the wildcard rule.";
          type = (types.nullOr types.str);
        };
        "http" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.HTTPIngressRuleValue"));
        };
      };


      config = {
        "host" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressServiceBackend" = {

      options = {
        "name" = mkOption {
          description = "Name is the referenced service. The service must exist in the same namespace as the Ingress object.";
          type = types.str;
        };
        "port" = mkOption {
          description = "Port of the referenced service. A port name or port number is required for a IngressServiceBackend.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.ServiceBackendPort"));
        };
      };


      config = {
        "port" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressSpec" = {

      options = {
        "defaultBackend" = mkOption {
          description = "DefaultBackend is the backend that should handle requests that don't match any rule. If Rules are not specified, DefaultBackend must be specified. If DefaultBackend is not set, the handling of requests that do not match any of the rules will be up to the Ingress controller.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressBackend"));
        };
        "ingressClassName" = mkOption {
          description = "IngressClassName is the name of an IngressClass cluster resource. Ingress controller implementations use this field to know whether they should be serving this Ingress resource, by a transitive connection (controller -> IngressClass -> Ingress resource). Although the `kubernetes.io/ingress.class` annotation (simple constant name) was never formally defined, it was widely supported by Ingress controllers to create a direct binding between Ingress controller and Ingress resources. Newly created Ingress resources should prefer using the field. However, even though the annotation is officially deprecated, for backwards compatibility reasons, ingress controllers should still honor that annotation if present.";
          type = (types.nullOr types.str);
        };
        "rules" = mkOption {
          description = "A list of host rules used to configure the Ingress. If unspecified, or no rule matches, all traffic is sent to the default backend.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.IngressRule")));
        };
        "tls" = mkOption {
          description = "TLS configuration. Currently the Ingress only supports a single TLS port, 443. If multiple members of this list specify different hosts, they will be multiplexed on the same port according to the hostname specified through the SNI TLS extension, if the ingress controller fulfilling the ingress supports SNI.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.IngressTLS")));
        };
      };


      config = {
        "defaultBackend" = mkOverride 1002 null;
        "ingressClassName" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressStatus" = {

      options = {
        "loadBalancer" = mkOption {
          description = "LoadBalancer contains the current status of the load-balancer.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IngressLoadBalancerStatus"));
        };
      };


      config = {
        "loadBalancer" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.IngressTLS" = {

      options = {
        "hosts" = mkOption {
          description = "Hosts are a list of hosts included in the TLS certificate. The values in this list must match the name/s used in the tlsSecret. Defaults to the wildcard host setting for the loadbalancer controller fulfilling this Ingress, if left unspecified.";
          type = (types.nullOr (types.listOf types.str));
        };
        "secretName" = mkOption {
          description = "SecretName is the name of the secret used to terminate TLS traffic on port 443. Field is left optional to allow TLS routing based on SNI hostname alone. If the SNI host in a listener conflicts with the \"Host\" header field used by an IngressRule, the SNI host is used for termination and value of the Host header is used for routing.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "hosts" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicy" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior for this NetworkPolicy.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.NetworkPolicySpec"));
        };
        "status" = mkOption {
          description = "Status is the current state of the NetworkPolicy. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyEgressRule" = {

      options = {
        "ports" = mkOption {
          description = "List of destination ports for outgoing traffic. Each item in this list is combined using a logical OR. If this field is empty or missing, this rule matches all ports (traffic not restricted by port). If this field is present and contains at least one item, then this rule allows traffic only if the traffic matches at least one port in the list.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyPort")));
        };
        "to" = mkOption {
          description = "List of destinations for outgoing traffic of pods selected for this rule. Items in this list are combined using a logical OR operation. If this field is empty or missing, this rule matches all destinations (traffic not restricted by destination). If this field is present and contains at least one item, this rule allows traffic only if the traffic matches at least one item in the to list.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyPeer")));
        };
      };


      config = {
        "ports" = mkOverride 1002 null;
        "to" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyIngressRule" = {

      options = {
        "from" = mkOption {
          description = "List of sources which should be able to access the pods selected for this rule. Items in this list are combined using a logical OR operation. If this field is empty or missing, this rule matches all sources (traffic not restricted by source). If this field is present and contains at least one item, this rule allows traffic only if the traffic matches at least one item in the from list.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyPeer")));
        };
        "ports" = mkOption {
          description = "List of ports which should be made accessible on the pods selected for this rule. Each item in this list is combined using a logical OR. If this field is empty or missing, this rule matches all ports (traffic not restricted by port). If this field is present and contains at least one item, then this rule allows traffic only if the traffic matches at least one port in the list.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyPort")));
        };
      };


      config = {
        "from" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of schema objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicy"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyPeer" = {

      options = {
        "ipBlock" = mkOption {
          description = "IPBlock defines policy on a particular IPBlock. If this field is set then neither of the other fields can be.";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1.IPBlock"));
        };
        "namespaceSelector" = mkOption {
          description = "Selects Namespaces using cluster-scoped labels. This field follows standard label selector semantics; if present but empty, it selects all namespaces.\n\nIf PodSelector is also set, then the NetworkPolicyPeer as a whole selects the Pods matching PodSelector in the Namespaces selected by NamespaceSelector. Otherwise it selects all Pods in the Namespaces selected by NamespaceSelector.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "podSelector" = mkOption {
          description = "This is a label selector which selects Pods. This field follows standard label selector semantics; if present but empty, it selects all pods.\n\nIf NamespaceSelector is also set, then the NetworkPolicyPeer as a whole selects the Pods matching PodSelector in the Namespaces selected by NamespaceSelector. Otherwise it selects the Pods matching PodSelector in the policy's own Namespace.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
      };


      config = {
        "ipBlock" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "podSelector" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyPort" = {

      options = {
        "endPort" = mkOption {
          description = "If set, indicates that the range of ports from port to endPort, inclusive, should be allowed by the policy. This field cannot be defined if the port field is not defined or if the port field is defined as a named (string) port. The endPort must be equal or greater than port.";
          type = (types.nullOr types.int);
        };
        "port" = mkOption {
          description = "The port on the given protocol. This can either be a numerical or named port on a pod. If this field is not provided, this matches all port names and numbers. If present, only traffic on the specified protocol AND port will be matched.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "protocol" = mkOption {
          description = "The protocol (TCP, UDP, or SCTP) which traffic must match. If not specified, this field defaults to TCP.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "endPort" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicySpec" = {

      options = {
        "egress" = mkOption {
          description = "List of egress rules to be applied to the selected pods. Outgoing traffic is allowed if there are no NetworkPolicies selecting the pod (and cluster policy otherwise allows the traffic), OR if the traffic matches at least one egress rule across all of the NetworkPolicy objects whose podSelector matches the pod. If this field is empty then this NetworkPolicy limits all outgoing traffic (and serves solely to ensure that the pods it selects are isolated by default). This field is beta-level in 1.8";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyEgressRule")));
        };
        "ingress" = mkOption {
          description = "List of ingress rules to be applied to the selected pods. Traffic is allowed to a pod if there are no NetworkPolicies selecting the pod (and cluster policy otherwise allows the traffic), OR if the traffic source is the pod's local node, OR if the traffic matches at least one ingress rule across all of the NetworkPolicy objects whose podSelector matches the pod. If this field is empty then this NetworkPolicy does not allow any traffic (and serves solely to ensure that the pods it selects are isolated by default)";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.networking.v1.NetworkPolicyIngressRule")));
        };
        "podSelector" = mkOption {
          description = "Selects the pods to which this NetworkPolicy object applies. The array of ingress rules is applied to any pods selected by this field. Multiple network policies can select the same set of pods. In this case, the ingress rules for each are combined additively. This field is NOT optional and follows standard label selector semantics. An empty podSelector matches all pods in this namespace.";
          type = (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector");
        };
        "policyTypes" = mkOption {
          description = "List of rule types that the NetworkPolicy relates to. Valid options are [\"Ingress\"], [\"Egress\"], or [\"Ingress\", \"Egress\"]. If this field is not specified, it will default based on the existence of Ingress or Egress rules; policies that contain an Egress section are assumed to affect Egress, and all policies (whether or not they contain an Ingress section) are assumed to affect Ingress. If you want to write an egress-only policy, you must explicitly specify policyTypes [ \"Egress\" ]. Likewise, if you want to write a policy that specifies that no egress is allowed, you must specify a policyTypes value that include \"Egress\" (since such a policy would not include an Egress section and would otherwise default to just [ \"Ingress\" ]). This field is beta-level in 1.8";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "egress" = mkOverride 1002 null;
        "ingress" = mkOverride 1002 null;
        "policyTypes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.NetworkPolicyStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions holds an array of metav1.Condition that describe the state of the NetworkPolicy. Current service state";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.apimachinery.pkg.apis.meta.v1.Condition" "type"));
          apply = attrsToList;
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1.ServiceBackendPort" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the port on the Service. This is a mutually exclusive setting with \"Number\".";
          type = (types.nullOr types.str);
        };
        "number" = mkOption {
          description = "Number is the numerical port number (e.g. 80) on the Service. This is a mutually exclusive setting with \"Name\".";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "number" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1alpha1.ClusterCIDR" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec is the desired state of the ClusterCIDR. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr (submoduleOf "io.k8s.api.networking.v1alpha1.ClusterCIDRSpec"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1alpha1.ClusterCIDRList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of ClusterCIDRs.";
          type = (types.listOf (submoduleOf "io.k8s.api.networking.v1alpha1.ClusterCIDR"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.networking.v1alpha1.ClusterCIDRSpec" = {

      options = {
        "ipv4" = mkOption {
          description = "IPv4 defines an IPv4 IP block in CIDR notation(e.g. \"10.0.0.0/8\"). At least one of IPv4 and IPv6 must be specified. This field is immutable.";
          type = (types.nullOr types.str);
        };
        "ipv6" = mkOption {
          description = "IPv6 defines an IPv6 IP block in CIDR notation(e.g. \"2001:db8::/64\"). At least one of IPv4 and IPv6 must be specified. This field is immutable.";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector defines which nodes the config is applicable to. An empty or nil NodeSelector selects all nodes. This field is immutable.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSelector"));
        };
        "perNodeHostBits" = mkOption {
          description = "PerNodeHostBits defines the number of host bits to be configured per node. A subnet mask determines how much of the address is used for network bits and host bits. For example an IPv4 address of 192.168.0.0/24, splits the address into 24 bits for the network portion and 8 bits for the host portion. To allocate 256 IPs, set this field to 8 (a /24 mask for IPv4 or a /120 for IPv6). Minimum value is 4 (16 IPs). This field is immutable.";
          type = types.int;
        };
      };


      config = {
        "ipv4" = mkOverride 1002 null;
        "ipv6" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.node.v1.Overhead" = {

      options = {
        "podFixed" = mkOption {
          description = "PodFixed represents the fixed resource overhead associated with running a pod.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };


      config = {
        "podFixed" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.node.v1.RuntimeClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "handler" = mkOption {
          description = "Handler specifies the underlying runtime and configuration that the CRI implementation will use to handle pods of this class. The possible values are specific to the node & CRI configuration.  It is assumed that all handlers are available on every node, and handlers of the same name are equivalent on every node. For example, a handler called \"runc\" might specify that the runc OCI runtime (using native Linux containers) will be used to run the containers in a pod. The Handler must be lowercase, conform to the DNS Label (RFC 1123) requirements, and is immutable.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "overhead" = mkOption {
          description = "Overhead represents the resource overhead associated with running a pod for a given RuntimeClass. For more details, see\n https://kubernetes.io/docs/concepts/scheduling-eviction/pod-overhead/";
          type = (types.nullOr (submoduleOf "io.k8s.api.node.v1.Overhead"));
        };
        "scheduling" = mkOption {
          description = "Scheduling holds the scheduling constraints to ensure that pods running with this RuntimeClass are scheduled to nodes that support it. If scheduling is nil, this RuntimeClass is assumed to be supported by all nodes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.node.v1.Scheduling"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "overhead" = mkOverride 1002 null;
        "scheduling" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.node.v1.RuntimeClassList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of schema objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.node.v1.RuntimeClass"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.node.v1.Scheduling" = {

      options = {
        "nodeSelector" = mkOption {
          description = "nodeSelector lists labels that must be present on nodes that support this RuntimeClass. Pods using this RuntimeClass can only be scheduled to a node matched by this selector. The RuntimeClass nodeSelector is merged with a pod's existing nodeSelector. Any conflicts will cause the pod to be rejected in admission.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "tolerations" = mkOption {
          description = "tolerations are appended (excluding duplicates) to pods running with this RuntimeClass during admission, effectively unioning the set of nodes tolerated by the pod and the RuntimeClass.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.Toleration")));
        };
      };


      config = {
        "nodeSelector" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.policy.v1.Eviction" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "deleteOptions" = mkOption {
          description = "DeleteOptions may be provided";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.DeleteOptions"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "ObjectMeta describes the pod that is being evicted.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "deleteOptions" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.policy.v1.PodDisruptionBudget" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired behavior of the PodDisruptionBudget.";
          type = (types.nullOr (submoduleOf "io.k8s.api.policy.v1.PodDisruptionBudgetSpec"));
        };
        "status" = mkOption {
          description = "Most recently observed status of the PodDisruptionBudget.";
          type = (types.nullOr (submoduleOf "io.k8s.api.policy.v1.PodDisruptionBudgetStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.policy.v1.PodDisruptionBudgetList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of PodDisruptionBudgets";
          type = (types.listOf (submoduleOf "io.k8s.api.policy.v1.PodDisruptionBudget"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.policy.v1.PodDisruptionBudgetSpec" = {

      options = {
        "maxUnavailable" = mkOption {
          description = "An eviction is allowed if at most \"maxUnavailable\" pods selected by \"selector\" are unavailable after the eviction, i.e. even in absence of the evicted pod. For example, one can prevent all voluntary evictions by specifying 0. This is a mutually exclusive setting with \"minAvailable\".";
          type = (types.nullOr (types.either types.int types.str));
        };
        "minAvailable" = mkOption {
          description = "An eviction is allowed if at least \"minAvailable\" pods selected by \"selector\" will still be available after the eviction, i.e. even in the absence of the evicted pod.  So for example you can prevent all voluntary evictions by specifying \"100%\".";
          type = (types.nullOr (types.either types.int types.str));
        };
        "selector" = mkOption {
          description = "Label query over pods whose evictions are managed by the disruption budget. A null selector will match no pods, while an empty ({}) selector will select all pods within the namespace.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "unhealthyPodEvictionPolicy" = mkOption {
          description = "UnhealthyPodEvictionPolicy defines the criteria for when unhealthy pods should be considered for eviction. Current implementation considers healthy pods, as pods that have status.conditions item with type=\"Ready\",status=\"True\".\n\nValid policies are IfHealthyBudget and AlwaysAllow. If no policy is specified, the default behavior will be used, which corresponds to the IfHealthyBudget policy.\n\nIfHealthyBudget policy means that running pods (status.phase=\"Running\"), but not yet healthy can be evicted only if the guarded application is not disrupted (status.currentHealthy is at least equal to status.desiredHealthy). Healthy pods will be subject to the PDB for eviction.\n\nAlwaysAllow policy means that all running pods (status.phase=\"Running\"), but not yet healthy are considered disrupted and can be evicted regardless of whether the criteria in a PDB is met. This means perspective running pods of a disrupted application might not get a chance to become healthy. Healthy pods will be subject to the PDB for eviction.\n\nAdditional policies may be added in the future. Clients making eviction decisions should disallow eviction of unhealthy pods if they encounter an unrecognized policy in this field.\n\nThis field is alpha-level. The eviction API uses this field when the feature gate PDBUnhealthyPodEvictionPolicy is enabled (disabled by default).";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "maxUnavailable" = mkOverride 1002 null;
        "minAvailable" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "unhealthyPodEvictionPolicy" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.policy.v1.PodDisruptionBudgetStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Conditions contain conditions for PDB. The disruption controller sets the DisruptionAllowed condition. The following are known values for the reason field (additional reasons could be added in the future): - SyncFailed: The controller encountered an error and wasn't able to compute\n              the number of allowed disruptions. Therefore no disruptions are\n              allowed and the status of the condition will be False.\n- InsufficientPods: The number of pods are either at or below the number\n                    required by the PodDisruptionBudget. No disruptions are\n                    allowed and the status of the condition will be False.\n- SufficientPods: There are more pods than required by the PodDisruptionBudget.\n                  The condition will be True, and the number of allowed\n                  disruptions are provided by the disruptionsAllowed property.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.apimachinery.pkg.apis.meta.v1.Condition" "type"));
          apply = attrsToList;
        };
        "currentHealthy" = mkOption {
          description = "current number of healthy pods";
          type = types.int;
        };
        "desiredHealthy" = mkOption {
          description = "minimum desired number of healthy pods";
          type = types.int;
        };
        "disruptedPods" = mkOption {
          description = "DisruptedPods contains information about pods whose eviction was processed by the API server eviction subresource handler but has not yet been observed by the PodDisruptionBudget controller. A pod will be in this map from the time when the API server processed the eviction request to the time when the pod is seen by PDB controller as having been marked for deletion (or after a timeout). The key in the map is the name of the pod and the value is the time when the API server processed the eviction request. If the deletion didn't occur and a pod is still there it will be removed from the list automatically by PodDisruptionBudget controller after some time. If everything goes smooth this map should be empty for the most of the time. Large number of entries in the map may indicate problems with pod deletions.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "disruptionsAllowed" = mkOption {
          description = "Number of pod disruptions that are currently allowed.";
          type = types.int;
        };
        "expectedPods" = mkOption {
          description = "total number of pods counted by this disruption budget";
          type = types.int;
        };
        "observedGeneration" = mkOption {
          description = "Most recent generation observed when updating this PDB status. DisruptionsAllowed and other status information is valid only if observedGeneration equals to PDB's object generation.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
        "disruptedPods" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.AggregationRule" = {

      options = {
        "clusterRoleSelectors" = mkOption {
          description = "ClusterRoleSelectors holds a list of selectors which will be used to find ClusterRoles and create the rules. If any of the selectors match, then the ClusterRole's permissions will be added";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector")));
        };
      };


      config = {
        "clusterRoleSelectors" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.ClusterRole" = {

      options = {
        "aggregationRule" = mkOption {
          description = "AggregationRule is an optional field that describes how to build the Rules for this ClusterRole. If AggregationRule is set, then the Rules are controller managed and direct changes to Rules will be stomped by the controller.";
          type = (types.nullOr (submoduleOf "io.k8s.api.rbac.v1.AggregationRule"));
        };
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "rules" = mkOption {
          description = "Rules holds all the PolicyRules for this ClusterRole";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.rbac.v1.PolicyRule")));
        };
      };


      config = {
        "aggregationRule" = mkOverride 1002 null;
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.ClusterRoleBinding" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "roleRef" = mkOption {
          description = "RoleRef can only reference a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error.";
          type = (submoduleOf "io.k8s.api.rbac.v1.RoleRef");
        };
        "subjects" = mkOption {
          description = "Subjects holds references to the objects the role applies to.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.rbac.v1.Subject")));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "subjects" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.ClusterRoleBindingList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of ClusterRoleBindings";
          type = (types.listOf (submoduleOf "io.k8s.api.rbac.v1.ClusterRoleBinding"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.ClusterRoleList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of ClusterRoles";
          type = (types.listOf (submoduleOf "io.k8s.api.rbac.v1.ClusterRole"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.PolicyRule" = {

      options = {
        "apiGroups" = mkOption {
          description = "APIGroups is the name of the APIGroup that contains the resources.  If multiple API groups are specified, any action requested against one of the enumerated resources in any API group will be allowed. \"\" represents the core API group and \"*\" represents all API groups.";
          type = (types.nullOr (types.listOf types.str));
        };
        "nonResourceURLs" = mkOption {
          description = "NonResourceURLs is a set of partial urls that a user should have access to.  *s are allowed, but only as the full, final step in the path Since non-resource URLs are not namespaced, this field is only applicable for ClusterRoles referenced from a ClusterRoleBinding. Rules can either apply to API resources (such as \"pods\" or \"secrets\") or non-resource URL paths (such as \"/api\"),  but not both.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resourceNames" = mkOption {
          description = "ResourceNames is an optional white list of names that the rule applies to.  An empty set means that everything is allowed.";
          type = (types.nullOr (types.listOf types.str));
        };
        "resources" = mkOption {
          description = "Resources is a list of resources this rule applies to. '*' represents all resources.";
          type = (types.nullOr (types.listOf types.str));
        };
        "verbs" = mkOption {
          description = "Verbs is a list of Verbs that apply to ALL the ResourceKinds contained in this rule. '*' represents all verbs.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "apiGroups" = mkOverride 1002 null;
        "nonResourceURLs" = mkOverride 1002 null;
        "resourceNames" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.Role" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "rules" = mkOption {
          description = "Rules holds all the PolicyRules for this Role";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.rbac.v1.PolicyRule")));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.RoleBinding" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "roleRef" = mkOption {
          description = "RoleRef can reference a Role in the current namespace or a ClusterRole in the global namespace. If the RoleRef cannot be resolved, the Authorizer must return an error.";
          type = (submoduleOf "io.k8s.api.rbac.v1.RoleRef");
        };
        "subjects" = mkOption {
          description = "Subjects holds references to the objects the role applies to.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.rbac.v1.Subject")));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "subjects" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.RoleBindingList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of RoleBindings";
          type = (types.listOf (submoduleOf "io.k8s.api.rbac.v1.RoleBinding"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.RoleList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is a list of Roles";
          type = (types.listOf (submoduleOf "io.k8s.api.rbac.v1.Role"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.rbac.v1.RoleRef" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.api.rbac.v1.Subject" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup holds the API group of the referenced subject. Defaults to \"\" for ServiceAccount subjects. Defaults to \"rbac.authorization.k8s.io\" for User and Group subjects.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of object being referenced. Values defined by this API group are \"User\", \"Group\", and \"ServiceAccount\". If the Authorizer does not recognized the kind value, the Authorizer should report an error.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the object being referenced.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace of the referenced object.  If the object kind is non-namespace, such as \"User\" or \"Group\", and this value is not empty the Authorizer should report an error.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.AllocationResult" = {

      options = {
        "availableOnNodes" = mkOption {
          description = "This field will get set by the resource driver after it has allocated the resource driver to inform the scheduler where it can schedule Pods using the ResourceClaim.\n\nSetting this field is optional. If null, the resource is available everywhere.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSelector"));
        };
        "resourceHandle" = mkOption {
          description = "ResourceHandle contains arbitrary data returned by the driver after a successful allocation. This is opaque for Kubernetes. Driver documentation may explain to users how to interpret this data if needed.\n\nThe maximum size of this field is 16KiB. This may get increased in the future, but not reduced.";
          type = (types.nullOr types.str);
        };
        "shareable" = mkOption {
          description = "Shareable determines whether the resource supports more than one consumer at a time.";
          type = (types.nullOr types.bool);
        };
      };


      config = {
        "availableOnNodes" = mkOverride 1002 null;
        "resourceHandle" = mkOverride 1002 null;
        "shareable" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.PodScheduling" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec describes where resources for the Pod are needed.";
          type = (submoduleOf "io.k8s.api.resource.v1alpha1.PodSchedulingSpec");
        };
        "status" = mkOption {
          description = "Status describes where resources for the Pod can be allocated.";
          type = (types.nullOr (submoduleOf "io.k8s.api.resource.v1alpha1.PodSchedulingStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.PodSchedulingList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of PodScheduling objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.PodScheduling"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.PodSchedulingSpec" = {

      options = {
        "potentialNodes" = mkOption {
          description = "PotentialNodes lists nodes where the Pod might be able to run.\n\nThe size of this field is limited to 128. This is large enough for many clusters. Larger clusters may need more attempts to find a node that suits all pending resources. This may get increased in the future, but not reduced.";
          type = (types.nullOr (types.listOf types.str));
        };
        "selectedNode" = mkOption {
          description = "SelectedNode is the node for which allocation of ResourceClaims that are referenced by the Pod and that use \"WaitForFirstConsumer\" allocation is to be attempted.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "potentialNodes" = mkOverride 1002 null;
        "selectedNode" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.PodSchedulingStatus" = {

      options = {
        "resourceClaims" = mkOption {
          description = "ResourceClaims describes resource availability for each pod.spec.resourceClaim entry where the corresponding ResourceClaim uses \"WaitForFirstConsumer\" allocation mode.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimSchedulingStatus")));
        };
      };


      config = {
        "resourceClaims" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaim" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec describes the desired attributes of a resource that then needs to be allocated. It can only be set once when creating the ResourceClaim.";
          type = (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimSpec");
        };
        "status" = mkOption {
          description = "Status describes whether the resource is available and with which attributes.";
          type = (types.nullOr (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimConsumerReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. It is empty for the core API. This matches the group in the APIVersion that is used when creating the resources.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced.";
          type = types.str;
        };
        "resource" = mkOption {
          description = "Resource is the type of resource being referenced, for example \"pods\".";
          type = types.str;
        };
        "uid" = mkOption {
          description = "UID identifies exactly one incarnation of the resource.";
          type = types.str;
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of resource claims.";
          type = (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaim"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimParametersReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. It is empty for the core API. This matches the group in the APIVersion that is used when creating the resources.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced. This is the same value as in the parameter object's metadata, for example \"ConfigMap\".";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced.";
          type = types.str;
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimSchedulingStatus" = {

      options = {
        "name" = mkOption {
          description = "Name matches the pod.spec.resourceClaims[*].Name field.";
          type = (types.nullOr types.str);
        };
        "unsuitableNodes" = mkOption {
          description = "UnsuitableNodes lists nodes that the ResourceClaim cannot be allocated for.\n\nThe size of this field is limited to 128, the same as for PodSchedulingSpec.PotentialNodes. This may get increased in the future, but not reduced.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "unsuitableNodes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimSpec" = {

      options = {
        "allocationMode" = mkOption {
          description = "Allocation can start immediately or when a Pod wants to use the resource. \"WaitForFirstConsumer\" is the default.";
          type = (types.nullOr types.str);
        };
        "parametersRef" = mkOption {
          description = "ParametersRef references a separate object with arbitrary parameters that will be used by the driver when allocating a resource for the claim.\n\nThe object must be in the same namespace as the ResourceClaim.";
          type = (types.nullOr (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimParametersReference"));
        };
        "resourceClassName" = mkOption {
          description = "ResourceClassName references the driver and additional parameters via the name of a ResourceClass that was created as part of the driver deployment.";
          type = types.str;
        };
      };


      config = {
        "allocationMode" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimStatus" = {

      options = {
        "allocation" = mkOption {
          description = "Allocation is set by the resource driver once a resource has been allocated successfully. If this is not specified, the resource is not yet allocated.";
          type = (types.nullOr (submoduleOf "io.k8s.api.resource.v1alpha1.AllocationResult"));
        };
        "deallocationRequested" = mkOption {
          description = "DeallocationRequested indicates that a ResourceClaim is to be deallocated.\n\nThe driver then must deallocate this claim and reset the field together with clearing the Allocation field.\n\nWhile DeallocationRequested is set, no new consumers may be added to ReservedFor.";
          type = (types.nullOr types.bool);
        };
        "driverName" = mkOption {
          description = "DriverName is a copy of the driver name from the ResourceClass at the time when allocation started.";
          type = (types.nullOr types.str);
        };
        "reservedFor" = mkOption {
          description = "ReservedFor indicates which entities are currently allowed to use the claim. A Pod which references a ResourceClaim which is not reserved for that Pod will not be started.\n\nThere can be at most 32 such reservations. This may get increased in the future, but not reduced.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimConsumerReference")));
        };
      };


      config = {
        "allocation" = mkOverride 1002 null;
        "deallocationRequested" = mkOverride 1002 null;
        "driverName" = mkOverride 1002 null;
        "reservedFor" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimTemplate" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Describes the ResourceClaim that is to be generated.\n\nThis field is immutable. A ResourceClaim will get created by the control plane for a Pod when needed and then not get updated anymore.";
          type = (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimTemplateSpec");
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimTemplateList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of resource claim templates.";
          type = (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimTemplate"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClaimTemplateSpec" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta may contain labels and annotations that will be copied into the PVC when creating it. No other fields are allowed and will be rejected during validation.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec for the ResourceClaim. The entire content is copied unchanged into the ResourceClaim that gets created from this template. The same fields as in a ResourceClaim are also valid here.";
          type = (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClaimSpec");
        };
      };


      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "driverName" = mkOption {
          description = "DriverName defines the name of the dynamic resource driver that is used for allocation of a ResourceClaim that uses this class.\n\nResource drivers have a unique name in forward domain order (acme.example.com).";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "parametersRef" = mkOption {
          description = "ParametersRef references an arbitrary separate object that may hold parameters that will be used by the driver when allocating a resource that uses this class. A dynamic resource driver can distinguish between parameters stored here and and those stored in ResourceClaimSpec.";
          type = (types.nullOr (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClassParametersReference"));
        };
        "suitableNodes" = mkOption {
          description = "Only nodes matching the selector will be considered by the scheduler when trying to find a Node that fits a Pod when that Pod uses a ResourceClaim that has not been allocated yet.\n\nSetting this field is optional. If null, all nodes are candidates.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.NodeSelector"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "parametersRef" = mkOverride 1002 null;
        "suitableNodes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClassList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of resource classes.";
          type = (types.listOf (submoduleOf "io.k8s.api.resource.v1alpha1.ResourceClass"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.resource.v1alpha1.ResourceClassParametersReference" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced. It is empty for the core API. This matches the group in the APIVersion that is used when creating the resources.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced. This is the same value as in the parameter object's metadata.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced.";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "Namespace that contains the referenced resource. Must be empty for cluster-scoped resources and non-empty for namespaced resources.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiGroup" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.scheduling.v1.PriorityClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "description" = mkOption {
          description = "description is an arbitrary string that usually provides guidelines on when this priority class should be used.";
          type = (types.nullOr types.str);
        };
        "globalDefault" = mkOption {
          description = "globalDefault specifies whether this PriorityClass should be considered as the default priority for pods that do not have any priority class. Only one PriorityClass can be marked as `globalDefault`. However, if more than one PriorityClasses exists with their `globalDefault` field set to true, the smallest value of such global default PriorityClasses will be used as the default priority.";
          type = (types.nullOr types.bool);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "preemptionPolicy" = mkOption {
          description = "PreemptionPolicy is the Policy for preempting pods with lower priority. One of Never, PreemptLowerPriority. Defaults to PreemptLowerPriority if unset.";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "The value of this priority class. This is the actual priority that pods receive when they have the name of this class in their pod spec.";
          type = types.int;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "globalDefault" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "preemptionPolicy" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.scheduling.v1.PriorityClassList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of PriorityClasses";
          type = (types.listOf (submoduleOf "io.k8s.api.scheduling.v1.PriorityClass"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSIDriver" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata. metadata.Name indicates the name of the CSI driver that this object refers to; it MUST be the same name returned by the CSI GetPluginName() call for that driver. The driver name must be 63 characters or less, beginning and ending with an alphanumeric character ([a-z0-9A-Z]) with dashes (-), dots (.), and alphanumerics between. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the CSI Driver.";
          type = (submoduleOf "io.k8s.api.storage.v1.CSIDriverSpec");
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSIDriverList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of CSIDriver";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1.CSIDriver"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSIDriverSpec" = {

      options = {
        "attachRequired" = mkOption {
          description = "attachRequired indicates this CSI volume driver requires an attach operation (because it implements the CSI ControllerPublishVolume() method), and that the Kubernetes attach detach controller should call the attach volume interface which checks the volumeattachment status and waits until the volume is attached before proceeding to mounting. The CSI external-attacher coordinates with CSI volume driver and updates the volumeattachment status when the attach operation is complete. If the CSIDriverRegistry feature gate is enabled and the value is specified to false, the attach operation will be skipped. Otherwise the attach operation will be called.\n\nThis field is immutable.";
          type = (types.nullOr types.bool);
        };
        "fsGroupPolicy" = mkOption {
          description = "Defines if the underlying volume supports changing ownership and permission of the volume before being mounted. Refer to the specific FSGroupPolicy values for additional details.\n\nThis field is immutable.\n\nDefaults to ReadWriteOnceWithFSType, which will examine each volume to determine if Kubernetes should modify ownership and permissions of the volume. With the default policy the defined fsGroup will only be applied if a fstype is defined and the volume's access mode contains ReadWriteOnce.";
          type = (types.nullOr types.str);
        };
        "podInfoOnMount" = mkOption {
          description = "If set to true, podInfoOnMount indicates this CSI volume driver requires additional pod information (like podName, podUID, etc.) during mount operations. If set to false, pod information will not be passed on mount. Default is false. The CSI driver specifies podInfoOnMount as part of driver deployment. If true, Kubelet will pass pod information as VolumeContext in the CSI NodePublishVolume() calls. The CSI driver is responsible for parsing and validating the information passed in as VolumeContext. The following VolumeConext will be passed if podInfoOnMount is set to true. This list might grow, but the prefix will be used. \"csi.storage.k8s.io/pod.name\": pod.Name \"csi.storage.k8s.io/pod.namespace\": pod.Namespace \"csi.storage.k8s.io/pod.uid\": string(pod.UID) \"csi.storage.k8s.io/ephemeral\": \"true\" if the volume is an ephemeral inline volume\n                                defined by a CSIVolumeSource, otherwise \"false\"\n\n\"csi.storage.k8s.io/ephemeral\" is a new feature in Kubernetes 1.16. It is only required for drivers which support both the \"Persistent\" and \"Ephemeral\" VolumeLifecycleMode. Other drivers can leave pod info disabled and/or ignore this field. As Kubernetes 1.15 doesn't support this field, drivers can only support one mode when deployed on such a cluster and the deployment determines which mode that is, for example via a command line parameter of the driver.\n\nThis field is immutable.";
          type = (types.nullOr types.bool);
        };
        "requiresRepublish" = mkOption {
          description = "RequiresRepublish indicates the CSI driver wants `NodePublishVolume` being periodically called to reflect any possible change in the mounted volume. This field defaults to false.\n\nNote: After a successful initial NodePublishVolume call, subsequent calls to NodePublishVolume should only update the contents of the volume. New mount points will not be seen by a running container.";
          type = (types.nullOr types.bool);
        };
        "seLinuxMount" = mkOption {
          description = "SELinuxMount specifies if the CSI driver supports \"-o context\" mount option.\n\nWhen \"true\", the CSI driver must ensure that all volumes provided by this CSI driver can be mounted separately with different `-o context` options. This is typical for storage backends that provide volumes as filesystems on block devices or as independent shared volumes. Kubernetes will call NodeStage / NodePublish with \"-o context=xyz\" mount option when mounting a ReadWriteOncePod volume used in Pod that has explicitly set SELinux context. In the future, it may be expanded to other volume AccessModes. In any case, Kubernetes will ensure that the volume is mounted only with a single SELinux context.\n\nWhen \"false\", Kubernetes won't pass any special SELinux mount options to the driver. This is typical for volumes that represent subdirectories of a bigger shared filesystem.\n\nDefault is \"false\".";
          type = (types.nullOr types.bool);
        };
        "storageCapacity" = mkOption {
          description = "If set to true, storageCapacity indicates that the CSI volume driver wants pod scheduling to consider the storage capacity that the driver deployment will report by creating CSIStorageCapacity objects with capacity information.\n\nThe check can be enabled immediately when deploying a driver. In that case, provisioning new volumes with late binding will pause until the driver deployment has published some suitable CSIStorageCapacity object.\n\nAlternatively, the driver can be deployed with the field unset or false and it can be flipped later when storage capacity information has been published.\n\nThis field was immutable in Kubernetes <= 1.22 and now is mutable.";
          type = (types.nullOr types.bool);
        };
        "tokenRequests" = mkOption {
          description = "TokenRequests indicates the CSI driver needs pods' service account tokens it is mounting volume for to do necessary authentication. Kubelet will pass the tokens in VolumeContext in the CSI NodePublishVolume calls. The CSI driver should parse and validate the following VolumeContext: \"csi.storage.k8s.io/serviceAccount.tokens\": {\n  \"<audience>\": {\n    \"token\": <token>,\n    \"expirationTimestamp\": <expiration timestamp in RFC3339>,\n  },\n  ...\n}\n\nNote: Audience in each TokenRequest should be different and at most one token is empty string. To receive a new token after expiry, RequiresRepublish can be used to trigger NodePublishVolume periodically.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.storage.v1.TokenRequest")));
        };
        "volumeLifecycleModes" = mkOption {
          description = "volumeLifecycleModes defines what kind of volumes this CSI volume driver supports. The default if the list is empty is \"Persistent\", which is the usage defined by the CSI specification and implemented in Kubernetes via the usual PV/PVC mechanism. The other mode is \"Ephemeral\". In this mode, volumes are defined inline inside the pod spec with CSIVolumeSource and their lifecycle is tied to the lifecycle of that pod. A driver has to be aware of this because it is only going to get a NodePublishVolume call for such a volume. For more information about implementing this mode, see https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html A driver can support one or more of these modes and more modes may be added in the future. This field is beta.\n\nThis field is immutable.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "attachRequired" = mkOverride 1002 null;
        "fsGroupPolicy" = mkOverride 1002 null;
        "podInfoOnMount" = mkOverride 1002 null;
        "requiresRepublish" = mkOverride 1002 null;
        "seLinuxMount" = mkOverride 1002 null;
        "storageCapacity" = mkOverride 1002 null;
        "tokenRequests" = mkOverride 1002 null;
        "volumeLifecycleModes" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSINode" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "metadata.name must be the Kubernetes node name.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec is the specification of CSINode";
          type = (submoduleOf "io.k8s.api.storage.v1.CSINodeSpec");
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSINodeDriver" = {

      options = {
        "allocatable" = mkOption {
          description = "allocatable represents the volume resources of a node that are available for scheduling. This field is beta.";
          type = (types.nullOr (submoduleOf "io.k8s.api.storage.v1.VolumeNodeResources"));
        };
        "name" = mkOption {
          description = "This is the name of the CSI driver that this object refers to. This MUST be the same name returned by the CSI GetPluginName() call for that driver.";
          type = types.str;
        };
        "nodeID" = mkOption {
          description = "nodeID of the node from the driver point of view. This field enables Kubernetes to communicate with storage systems that do not share the same nomenclature for nodes. For example, Kubernetes may refer to a given node as \"node1\", but the storage system may refer to the same node as \"nodeA\". When Kubernetes issues a command to the storage system to attach a volume to a specific node, it can use this field to refer to the node name using the ID that the storage system will understand, e.g. \"nodeA\" instead of \"node1\". This field is required.";
          type = types.str;
        };
        "topologyKeys" = mkOption {
          description = "topologyKeys is the list of keys supported by the driver. When a driver is initialized on a cluster, it provides a set of topology keys that it understands (e.g. \"company.com/zone\", \"company.com/region\"). When a driver is initialized on a node, it provides the same topology keys along with values. Kubelet will expose these topology keys as labels on its own node object. When Kubernetes does topology aware provisioning, it can use this list to determine which labels it should retrieve from the node object and pass back to the driver. It is possible for different nodes to use different topology keys. This can be empty if driver does not support topology.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "allocatable" = mkOverride 1002 null;
        "topologyKeys" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSINodeList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items is the list of CSINode";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1.CSINode"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSINodeSpec" = {

      options = {
        "drivers" = mkOption {
          description = "drivers is a list of information of all CSI Drivers existing on a node. If all drivers in the list are uninstalled, this can become empty.";
          type = (coerceAttrsOfSubmodulesToListByKey "io.k8s.api.storage.v1.CSINodeDriver" "name");
          apply = attrsToList;
        };
      };


      config = { };

    };
    "io.k8s.api.storage.v1.CSIStorageCapacity" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "Capacity is the value reported by the CSI driver in its GetCapacityResponse for a GetCapacityRequest with topology and parameters that match the previous fields.\n\nThe semantic is currently (CSI spec 1.2) defined as: The available capacity, in bytes, of the storage that can be used to provision volumes. If not set, that information is currently unavailable.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "maximumVolumeSize" = mkOption {
          description = "MaximumVolumeSize is the value reported by the CSI driver in its GetCapacityResponse for a GetCapacityRequest with topology and parameters that match the previous fields.\n\nThis is defined since CSI spec 1.4.0 as the largest size that may be used in a CreateVolumeRequest.capacity_range.required_bytes field to create a volume with the same parameters as those in GetCapacityRequest. The corresponding value in the Kubernetes API is ResourceRequirements.Requests in a volume claim.";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. The name has no particular meaning. It must be be a DNS subdomain (dots allowed, 253 characters). To ensure that there are no conflicts with other CSI drivers on the cluster, the recommendation is to use csisc-<uuid>, a generated name, or a reverse-domain name which ends with the unique CSI driver name.\n\nObjects are namespaced.\n\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "nodeTopology" = mkOption {
          description = "NodeTopology defines which nodes have access to the storage for which capacity was reported. If not set, the storage is not accessible from any node in the cluster. If empty, the storage is accessible from all nodes. This field is immutable.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "storageClassName" = mkOption {
          description = "The name of the StorageClass that the reported capacity applies to. It must meet the same requirements as the name of a StorageClass object (non-empty, DNS subdomain). If that object no longer exists, the CSIStorageCapacity object is obsolete and should be removed by its creator. This field is immutable.";
          type = types.str;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "maximumVolumeSize" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "nodeTopology" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.CSIStorageCapacityList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of CSIStorageCapacity objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1.CSIStorageCapacity"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.StorageClass" = {

      options = {
        "allowVolumeExpansion" = mkOption {
          description = "AllowVolumeExpansion shows whether the storage class allow volume expand";
          type = (types.nullOr types.bool);
        };
        "allowedTopologies" = mkOption {
          description = "Restrict the node topologies where volumes can be dynamically provisioned. Each volume plugin defines its own supported topology specifications. An empty TopologySelectorTerm list means there is no topology restriction. This field is only honored by servers that enable the VolumeScheduling feature.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.api.core.v1.TopologySelectorTerm")));
        };
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "mountOptions" = mkOption {
          description = "Dynamically provisioned PersistentVolumes of this storage class are created with these mountOptions, e.g. [\"ro\", \"soft\"]. Not validated - mount of the PVs will simply fail if one is invalid.";
          type = (types.nullOr (types.listOf types.str));
        };
        "parameters" = mkOption {
          description = "Parameters holds the parameters for the provisioner that should create volumes of this storage class.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "provisioner" = mkOption {
          description = "Provisioner indicates the type of the provisioner.";
          type = types.str;
        };
        "reclaimPolicy" = mkOption {
          description = "Dynamically provisioned PersistentVolumes of this storage class are created with this reclaimPolicy. Defaults to Delete.";
          type = (types.nullOr types.str);
        };
        "volumeBindingMode" = mkOption {
          description = "VolumeBindingMode indicates how PersistentVolumeClaims should be provisioned and bound.  When unset, VolumeBindingImmediate is used. This field is only honored by servers that enable the VolumeScheduling feature.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "allowVolumeExpansion" = mkOverride 1002 null;
        "allowedTopologies" = mkOverride 1002 null;
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "mountOptions" = mkOverride 1002 null;
        "parameters" = mkOverride 1002 null;
        "reclaimPolicy" = mkOverride 1002 null;
        "volumeBindingMode" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.StorageClassList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of StorageClasses";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1.StorageClass"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.TokenRequest" = {

      options = {
        "audience" = mkOption {
          description = "Audience is the intended audience of the token in \"TokenRequestSpec\". It will default to the audiences of kube apiserver.";
          type = types.str;
        };
        "expirationSeconds" = mkOption {
          description = "ExpirationSeconds is the duration of validity of the token in \"TokenRequestSpec\". It has the same default value of \"ExpirationSeconds\" in \"TokenRequestSpec\".";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "expirationSeconds" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeAttachment" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Specification of the desired attach/detach volume behavior. Populated by the Kubernetes system.";
          type = (submoduleOf "io.k8s.api.storage.v1.VolumeAttachmentSpec");
        };
        "status" = mkOption {
          description = "Status of the VolumeAttachment request. Populated by the entity completing the attach or detach operation, i.e. the external-attacher.";
          type = (types.nullOr (submoduleOf "io.k8s.api.storage.v1.VolumeAttachmentStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeAttachmentList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of VolumeAttachments";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1.VolumeAttachment"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeAttachmentSource" = {

      options = {
        "inlineVolumeSpec" = mkOption {
          description = "inlineVolumeSpec contains all the information necessary to attach a persistent volume defined by a pod's inline VolumeSource. This field is populated only for the CSIMigration feature. It contains translated fields from a pod's inline VolumeSource to a PersistentVolumeSpec. This field is beta-level and is only honored by servers that enabled the CSIMigration feature.";
          type = (types.nullOr (submoduleOf "io.k8s.api.core.v1.PersistentVolumeSpec"));
        };
        "persistentVolumeName" = mkOption {
          description = "Name of the persistent volume to attach.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "inlineVolumeSpec" = mkOverride 1002 null;
        "persistentVolumeName" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeAttachmentSpec" = {

      options = {
        "attacher" = mkOption {
          description = "Attacher indicates the name of the volume driver that MUST handle this request. This is the name returned by GetPluginName().";
          type = types.str;
        };
        "nodeName" = mkOption {
          description = "The node that the volume should be attached to.";
          type = types.str;
        };
        "source" = mkOption {
          description = "Source represents the volume that should be attached.";
          type = (submoduleOf "io.k8s.api.storage.v1.VolumeAttachmentSource");
        };
      };


      config = { };

    };
    "io.k8s.api.storage.v1.VolumeAttachmentStatus" = {

      options = {
        "attachError" = mkOption {
          description = "The last error encountered during attach operation, if any. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.";
          type = (types.nullOr (submoduleOf "io.k8s.api.storage.v1.VolumeError"));
        };
        "attached" = mkOption {
          description = "Indicates the volume is successfully attached. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.";
          type = types.bool;
        };
        "attachmentMetadata" = mkOption {
          description = "Upon successful attach, this field is populated with any information returned by the attach operation that must be passed into subsequent WaitForAttach or Mount calls. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "detachError" = mkOption {
          description = "The last error encountered during detach operation, if any. This field must only be set by the entity completing the detach operation, i.e. the external-attacher.";
          type = (types.nullOr (submoduleOf "io.k8s.api.storage.v1.VolumeError"));
        };
      };


      config = {
        "attachError" = mkOverride 1002 null;
        "attachmentMetadata" = mkOverride 1002 null;
        "detachError" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeError" = {

      options = {
        "message" = mkOption {
          description = "String detailing the error encountered during Attach or Detach operation. This string may be logged, so it should not contain sensitive information.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "Time the error was encountered.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1.VolumeNodeResources" = {

      options = {
        "count" = mkOption {
          description = "Maximum number of unique volumes managed by the CSI driver that can be used on a node. A volume that is both attached and mounted on a node is considered to be used once, not twice. The same rule applies for a unique volume that is shared among multiple pods on the same node. If this field is not specified, then the supported number of volumes on this node is unbounded.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "count" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1beta1.CSIStorageCapacity" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "Capacity is the value reported by the CSI driver in its GetCapacityResponse for a GetCapacityRequest with topology and parameters that match the previous fields.\n\nThe semantic is currently (CSI spec 1.2) defined as: The available capacity, in bytes, of the storage that can be used to provision volumes. If not set, that information is currently unavailable.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "maximumVolumeSize" = mkOption {
          description = "MaximumVolumeSize is the value reported by the CSI driver in its GetCapacityResponse for a GetCapacityRequest with topology and parameters that match the previous fields.\n\nThis is defined since CSI spec 1.4.0 as the largest size that may be used in a CreateVolumeRequest.capacity_range.required_bytes field to create a volume with the same parameters as those in GetCapacityRequest. The corresponding value in the Kubernetes API is ResourceRequirements.Requests in a volume claim.";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. The name has no particular meaning. It must be be a DNS subdomain (dots allowed, 253 characters). To ensure that there are no conflicts with other CSI drivers on the cluster, the recommendation is to use csisc-<uuid>, a generated name, or a reverse-domain name which ends with the unique CSI driver name.\n\nObjects are namespaced.\n\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "nodeTopology" = mkOption {
          description = "NodeTopology defines which nodes have access to the storage for which capacity was reported. If not set, the storage is not accessible from any node in the cluster. If empty, the storage is accessible from all nodes. This field is immutable.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector"));
        };
        "storageClassName" = mkOption {
          description = "The name of the StorageClass that the reported capacity applies to. It must meet the same requirements as the name of a StorageClass object (non-empty, DNS subdomain). If that object no longer exists, the CSIStorageCapacity object is obsolete and should be removed by its creator. This field is immutable.";
          type = types.str;
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "maximumVolumeSize" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "nodeTopology" = mkOverride 1002 null;
      };

    };
    "io.k8s.api.storage.v1beta1.CSIStorageCapacityList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of CSIStorageCapacity objects.";
          type = (types.listOf (submoduleOf "io.k8s.api.storage.v1beta1.CSIStorageCapacity"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceColumnDefinition" = {

      options = {
        "description" = mkOption {
          description = "description is a human readable description of this column.";
          type = (types.nullOr types.str);
        };
        "format" = mkOption {
          description = "format is an optional OpenAPI type definition for this column. The 'name' format is applied to the primary identifier column to assist in clients identifying column is the resource name. See https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#data-types for details.";
          type = (types.nullOr types.str);
        };
        "jsonPath" = mkOption {
          description = "jsonPath is a simple JSON path (i.e. with array notation) which is evaluated against each custom resource to produce the value for this column.";
          type = types.str;
        };
        "name" = mkOption {
          description = "name is a human readable name for the column.";
          type = types.str;
        };
        "priority" = mkOption {
          description = "priority is an integer defining the relative importance of this column compared to others. Lower numbers are considered higher priority. Columns that may be omitted in limited space scenarios should be given a priority greater than 0.";
          type = (types.nullOr types.int);
        };
        "type" = mkOption {
          description = "type is an OpenAPI type definition for this column. See https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#data-types for details.";
          type = types.str;
        };
      };


      config = {
        "description" = mkOverride 1002 null;
        "format" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceConversion" = {

      options = {
        "strategy" = mkOption {
          description = "strategy specifies how custom resources are converted between versions. Allowed values are: - `None`: The converter only change the apiVersion and would not touch any other field in the custom resource. - `Webhook`: API Server will call to an external webhook to do the conversion. Additional information\n  is needed for this option. This requires spec.preserveUnknownFields to be false, and spec.conversion.webhook to be set.";
          type = types.str;
        };
        "webhook" = mkOption {
          description = "webhook describes how to call the conversion webhook. Required when `strategy` is set to `Webhook`.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.WebhookConversion"));
        };
      };


      config = {
        "webhook" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec describes how the user wants the resources to appear";
          type = (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec");
        };
        "status" = mkOption {
          description = "status indicates the actual state of the CustomResourceDefinition";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "message is a human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "reason is a unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "status is the status of the condition. Can be True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type is the type of the condition. Types include Established, NamesAccepted and Terminating.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "items list individual CustomResourceDefinition objects";
          type = (types.listOf (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionNames" = {

      options = {
        "categories" = mkOption {
          description = "categories is a list of grouped resources this custom resource belongs to (e.g. 'all'). This is published in API discovery documents, and used by clients to support invocations like `kubectl get all`.";
          type = (types.nullOr (types.listOf types.str));
        };
        "kind" = mkOption {
          description = "kind is the serialized kind of the resource. It is normally CamelCase and singular. Custom resource instances will use this value as the `kind` attribute in API calls.";
          type = types.str;
        };
        "listKind" = mkOption {
          description = "listKind is the serialized kind of the list for this resource. Defaults to \"`kind`List\".";
          type = (types.nullOr types.str);
        };
        "plural" = mkOption {
          description = "plural is the plural name of the resource to serve. The custom resources are served under `/apis/<group>/<version>/.../<plural>`. Must match the name of the CustomResourceDefinition (in the form `<names.plural>.<group>`). Must be all lowercase.";
          type = types.str;
        };
        "shortNames" = mkOption {
          description = "shortNames are short names for the resource, exposed in API discovery documents, and used by clients to support invocations like `kubectl get <shortname>`. It must be all lowercase.";
          type = (types.nullOr (types.listOf types.str));
        };
        "singular" = mkOption {
          description = "singular is the singular name of the resource. It must be all lowercase. Defaults to lowercased `kind`.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "categories" = mkOverride 1002 null;
        "listKind" = mkOverride 1002 null;
        "shortNames" = mkOverride 1002 null;
        "singular" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionSpec" = {

      options = {
        "conversion" = mkOption {
          description = "conversion defines conversion settings for the CRD.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceConversion"));
        };
        "group" = mkOption {
          description = "group is the API group of the defined custom resource. The custom resources are served under `/apis/<group>/...`. Must match the name of the CustomResourceDefinition (in the form `<names.plural>.<group>`).";
          type = types.str;
        };
        "names" = mkOption {
          description = "names specify the resource and kind names for the custom resource.";
          type = (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionNames");
        };
        "preserveUnknownFields" = mkOption {
          description = "preserveUnknownFields indicates that object fields which are not specified in the OpenAPI schema should be preserved when persisting to storage. apiVersion, kind, metadata and known fields inside metadata are always preserved. This field is deprecated in favor of setting `x-preserve-unknown-fields` to true in `spec.versions[*].schema.openAPIV3Schema`. See https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#field-pruning for details.";
          type = (types.nullOr types.bool);
        };
        "scope" = mkOption {
          description = "scope indicates whether the defined custom resource is cluster- or namespace-scoped. Allowed values are `Cluster` and `Namespaced`.";
          type = types.str;
        };
        "versions" = mkOption {
          description = "versions is the list of all API versions of the defined custom resource. Version names are used to compute the order in which served versions are listed in API discovery. If the version string is \"kube-like\", it will sort above non \"kube-like\" version strings, which are ordered lexicographically. \"Kube-like\" versions start with a \"v\", then are followed by a number (the major version), then optionally the string \"alpha\" or \"beta\" and another number (the minor version). These are sorted first by GA > beta > alpha (where GA is a version with no suffix such as beta or alpha), and then by comparing major version, then minor version. An example sorted list of versions: v10, v2, v1, v11beta2, v10beta3, v3beta1, v12alpha1, v11alpha2, foo1, foo10.";
          type = (types.listOf (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionVersion"));
        };
      };


      config = {
        "conversion" = mkOverride 1002 null;
        "preserveUnknownFields" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionStatus" = {

      options = {
        "acceptedNames" = mkOption {
          description = "acceptedNames are the names that are actually being used to serve discovery. They may be different than the names in spec.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionNames"));
        };
        "conditions" = mkOption {
          description = "conditions indicate state for particular aspects of a CustomResourceDefinition";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionCondition")));
        };
        "storedVersions" = mkOption {
          description = "storedVersions lists all versions of CustomResources that were ever persisted. Tracking these versions allows a migration path for stored versions in etcd. The field is mutable so a migration controller can finish a migration to another version (ensuring no old objects are left in storage), and then remove the rest of the versions from this list. Versions may not be removed from `spec.versions` while they exist in this list.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "acceptedNames" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "storedVersions" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinitionVersion" = {

      options = {
        "additionalPrinterColumns" = mkOption {
          description = "additionalPrinterColumns specifies additional columns returned in Table output. See https://kubernetes.io/docs/reference/using-api/api-concepts/#receiving-resources-as-tables for details. If no columns are specified, a single column displaying the age of the custom resource is used.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceColumnDefinition")));
        };
        "deprecated" = mkOption {
          description = "deprecated indicates this version of the custom resource API is deprecated. When set to true, API requests to this version receive a warning header in the server response. Defaults to false.";
          type = (types.nullOr types.bool);
        };
        "deprecationWarning" = mkOption {
          description = "deprecationWarning overrides the default warning returned to API clients. May only be set when `deprecated` is true. The default warning indicates this version is deprecated and recommends use of the newest served version of equal or greater stability, if one exists.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "name is the version name, e.g. “v1”, “v2beta1”, etc. The custom resources are served under this version at `/apis/<group>/<version>/...` if `served` is true.";
          type = types.str;
        };
        "schema" = mkOption {
          description = "schema describes the schema used for validation, pruning, and defaulting of this version of the custom resource.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceValidation"));
        };
        "served" = mkOption {
          description = "served is a flag enabling/disabling this version from being served via REST APIs";
          type = types.bool;
        };
        "storage" = mkOption {
          description = "storage indicates this version should be used when persisting custom resources to storage. There must be exactly one version with storage=true.";
          type = types.bool;
        };
        "subresources" = mkOption {
          description = "subresources specify what subresources this version of the defined custom resource have.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresources"));
        };
      };


      config = {
        "additionalPrinterColumns" = mkOverride 1002 null;
        "deprecated" = mkOverride 1002 null;
        "deprecationWarning" = mkOverride 1002 null;
        "schema" = mkOverride 1002 null;
        "subresources" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresourceScale" = {

      options = {
        "labelSelectorPath" = mkOption {
          description = "labelSelectorPath defines the JSON path inside of a custom resource that corresponds to Scale `status.selector`. Only JSON paths without the array notation are allowed. Must be a JSON Path under `.status` or `.spec`. Must be set to work with HorizontalPodAutoscaler. The field pointed by this JSON path must be a string field (not a complex selector struct) which contains a serialized label selector in string form. More info: https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions#scale-subresource If there is no value under the given path in the custom resource, the `status.selector` value in the `/scale` subresource will default to the empty string.";
          type = (types.nullOr types.str);
        };
        "specReplicasPath" = mkOption {
          description = "specReplicasPath defines the JSON path inside of a custom resource that corresponds to Scale `spec.replicas`. Only JSON paths without the array notation are allowed. Must be a JSON Path under `.spec`. If there is no value under the given path in the custom resource, the `/scale` subresource will return an error on GET.";
          type = types.str;
        };
        "statusReplicasPath" = mkOption {
          description = "statusReplicasPath defines the JSON path inside of a custom resource that corresponds to Scale `status.replicas`. Only JSON paths without the array notation are allowed. Must be a JSON Path under `.status`. If there is no value under the given path in the custom resource, the `status.replicas` value in the `/scale` subresource will default to 0.";
          type = types.str;
        };
      };


      config = {
        "labelSelectorPath" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresourceStatus" = { };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresources" = {

      options = {
        "scale" = mkOption {
          description = "scale indicates the custom resource should serve a `/scale` subresource that returns an `autoscaling/v1` Scale object.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresourceScale"));
        };
        "status" = mkOption {
          description = "status indicates the custom resource should serve a `/status` subresource. When enabled: 1. requests to the custom resource primary endpoint ignore changes to the `status` stanza of the object. 2. requests to the custom resource `/status` subresource ignore changes to anything other than the `status` stanza of the object.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceSubresourceStatus"));
        };
      };


      config = {
        "scale" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceValidation" = {

      options = {
        "openAPIV3Schema" = mkOption {
          description = "openAPIV3Schema is the OpenAPI v3 schema to use for validation and pruning.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaProps"));
        };
      };


      config = {
        "openAPIV3Schema" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ExternalDocumentation" = {

      options = {
        "description" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "description" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON" = { };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaProps" = {

      options = {
        "$ref" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "$schema" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "additionalItems" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrBool"));
        };
        "additionalProperties" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrBool"));
        };
        "allOf" = mkOption {
          description = "";
          type = types.unspecified;
        };
        "anyOf" = mkOption {
          description = "";
          type = types.unspecified;
        };
        "default" = mkOption {
          description = "default is a default value for undefined object fields. Defaulting is a beta feature under the CustomResourceDefaulting feature gate. Defaulting requires spec.preserveUnknownFields to be false.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON"));
        };
        "definitions" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "dependencies" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "description" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "enum" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON")));
        };
        "example" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON"));
        };
        "exclusiveMaximum" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "exclusiveMinimum" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "externalDocs" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ExternalDocumentation"));
        };
        "format" = mkOption {
          description = "format is an OpenAPI v3 format string. Unknown formats are ignored. The following formats are validated:\n\n- bsonobjectid: a bson object ID, i.e. a 24 characters hex string - uri: an URI as parsed by Golang net/url.ParseRequestURI - email: an email address as parsed by Golang net/mail.ParseAddress - hostname: a valid representation for an Internet host name, as defined by RFC 1034, section 3.1 [RFC1034]. - ipv4: an IPv4 IP as parsed by Golang net.ParseIP - ipv6: an IPv6 IP as parsed by Golang net.ParseIP - cidr: a CIDR as parsed by Golang net.ParseCIDR - mac: a MAC address as parsed by Golang net.ParseMAC - uuid: an UUID that allows uppercase defined by the regex (?i)^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$ - uuid3: an UUID3 that allows uppercase defined by the regex (?i)^[0-9a-f]{8}-?[0-9a-f]{4}-?3[0-9a-f]{3}-?[0-9a-f]{4}-?[0-9a-f]{12}$ - uuid4: an UUID4 that allows uppercase defined by the regex (?i)^[0-9a-f]{8}-?[0-9a-f]{4}-?4[0-9a-f]{3}-?[89ab][0-9a-f]{3}-?[0-9a-f]{12}$ - uuid5: an UUID5 that allows uppercase defined by the regex (?i)^[0-9a-f]{8}-?[0-9a-f]{4}-?5[0-9a-f]{3}-?[89ab][0-9a-f]{3}-?[0-9a-f]{12}$ - isbn: an ISBN10 or ISBN13 number string like \"0321751043\" or \"978-0321751041\" - isbn10: an ISBN10 number string like \"0321751043\" - isbn13: an ISBN13 number string like \"978-0321751041\" - creditcard: a credit card number defined by the regex ^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11})$ with any non digit characters mixed in - ssn: a U.S. social security number following the regex ^\\d{3}[- ]?\\d{2}[- ]?\\d{4}$ - hexcolor: an hexadecimal color code like \"#FFFFFF: following the regex ^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$ - rgbcolor: an RGB color code like rgb like \"rgb(255,255,2559\" - byte: base64 encoded binary data - password: any kind of string - date: a date string like \"2006-01-02\" as defined by full-date in RFC3339 - duration: a duration string like \"22 ns\" as parsed by Golang time.ParseDuration or compatible with Scala duration format - datetime: a date time string like \"2014-12-15T19:30:20.000Z\" as defined by date-time in RFC3339.";
          type = (types.nullOr types.str);
        };
        "id" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrArray"));
        };
        "maxItems" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "maxLength" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "maxProperties" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "maximum" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "minItems" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "minLength" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "minProperties" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "minimum" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "multipleOf" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "not" = mkOption {
          description = "";
          type = types.unspecified;
        };
        "nullable" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "oneOf" = mkOption {
          description = "";
          type = types.unspecified;
        };
        "pattern" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "patternProperties" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "properties" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "required" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "title" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "uniqueItems" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "x-kubernetes-embedded-resource" = mkOption {
          description = "x-kubernetes-embedded-resource defines that the value is an embedded Kubernetes runtime.Object, with TypeMeta and ObjectMeta. The type must be object. It is allowed to further restrict the embedded object. kind, apiVersion and metadata are validated automatically. x-kubernetes-preserve-unknown-fields is allowed to be true, but does not have to be if the object is fully specified (up to kind, apiVersion, metadata).";
          type = (types.nullOr types.bool);
        };
        "x-kubernetes-int-or-string" = mkOption {
          description = "x-kubernetes-int-or-string specifies that this value is either an integer or a string. If this is true, an empty type is allowed and type as child of anyOf is permitted if following one of the following patterns:\n\n1) anyOf:\n   - type: integer\n   - type: string\n2) allOf:\n   - anyOf:\n     - type: integer\n     - type: string\n   - ... zero or more";
          type = (types.nullOr types.bool);
        };
        "x-kubernetes-list-map-keys" = mkOption {
          description = "x-kubernetes-list-map-keys annotates an array with the x-kubernetes-list-type `map` by specifying the keys used as the index of the map.\n\nThis tag MUST only be used on lists that have the \"x-kubernetes-list-type\" extension set to \"map\". Also, the values specified for this attribute must be a scalar typed field of the child structure (no nesting is supported).\n\nThe properties specified must either be required or have a default value, to ensure those properties are present for all list items.";
          type = (types.nullOr (types.listOf types.str));
        };
        "x-kubernetes-list-type" = mkOption {
          description = "x-kubernetes-list-type annotates an array to further describe its topology. This extension must only be used on lists and may have 3 possible values:\n\n1) `atomic`: the list is treated as a single entity, like a scalar.\n     Atomic lists will be entirely replaced when updated. This extension\n     may be used on any type of list (struct, scalar, ...).\n2) `set`:\n     Sets are lists that must not have multiple items with the same value. Each\n     value must be a scalar, an object with x-kubernetes-map-type `atomic` or an\n     array with x-kubernetes-list-type `atomic`.\n3) `map`:\n     These lists are like maps in that their elements have a non-index key\n     used to identify them. Order is preserved upon merge. The map tag\n     must only be used on a list with elements of type object.\nDefaults to atomic for arrays.";
          type = (types.nullOr types.str);
        };
        "x-kubernetes-map-type" = mkOption {
          description = "x-kubernetes-map-type annotates an object to further describe its topology. This extension must only be used when type is object and may have 2 possible values:\n\n1) `granular`:\n     These maps are actual maps (key-value pairs) and each fields are independent\n     from each other (they can each be manipulated by separate actors). This is\n     the default behaviour for all maps.\n2) `atomic`: the list is treated as a single entity, like a scalar.\n     Atomic maps will be entirely replaced when updated.";
          type = (types.nullOr types.str);
        };
        "x-kubernetes-preserve-unknown-fields" = mkOption {
          description = "x-kubernetes-preserve-unknown-fields stops the API server decoding step from pruning fields which are not specified in the validation schema. This affects fields recursively, but switches back to normal pruning behaviour if nested properties or additionalProperties are specified in the schema. This can either be true or undefined. False is forbidden.";
          type = (types.nullOr types.bool);
        };
        "x-kubernetes-validations" = mkOption {
          description = "x-kubernetes-validations describes a list of validation rules written in the CEL expression language. This field is an alpha-level. Using this field requires the feature gate `CustomResourceValidationExpressions` to be enabled.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ValidationRule" "rule"));
          apply = attrsToList;
        };
      };


      config = {
        "$ref" = mkOverride 1002 null;
        "$schema" = mkOverride 1002 null;
        "additionalItems" = mkOverride 1002 null;
        "additionalProperties" = mkOverride 1002 null;
        "allOf" = mkOverride 1002 null;
        "anyOf" = mkOverride 1002 null;
        "default" = mkOverride 1002 null;
        "definitions" = mkOverride 1002 null;
        "dependencies" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "enum" = mkOverride 1002 null;
        "example" = mkOverride 1002 null;
        "exclusiveMaximum" = mkOverride 1002 null;
        "exclusiveMinimum" = mkOverride 1002 null;
        "externalDocs" = mkOverride 1002 null;
        "format" = mkOverride 1002 null;
        "id" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "maxItems" = mkOverride 1002 null;
        "maxLength" = mkOverride 1002 null;
        "maxProperties" = mkOverride 1002 null;
        "maximum" = mkOverride 1002 null;
        "minItems" = mkOverride 1002 null;
        "minLength" = mkOverride 1002 null;
        "minProperties" = mkOverride 1002 null;
        "minimum" = mkOverride 1002 null;
        "multipleOf" = mkOverride 1002 null;
        "not" = mkOverride 1002 null;
        "nullable" = mkOverride 1002 null;
        "oneOf" = mkOverride 1002 null;
        "pattern" = mkOverride 1002 null;
        "patternProperties" = mkOverride 1002 null;
        "properties" = mkOverride 1002 null;
        "required" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
        "uniqueItems" = mkOverride 1002 null;
        "x-kubernetes-embedded-resource" = mkOverride 1002 null;
        "x-kubernetes-int-or-string" = mkOverride 1002 null;
        "x-kubernetes-list-map-keys" = mkOverride 1002 null;
        "x-kubernetes-list-type" = mkOverride 1002 null;
        "x-kubernetes-map-type" = mkOverride 1002 null;
        "x-kubernetes-preserve-unknown-fields" = mkOverride 1002 null;
        "x-kubernetes-validations" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrArray" = { };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrBool" = { };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaPropsOrStringArray" = { };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ServiceReference" = {

      options = {
        "name" = mkOption {
          description = "name is the name of the service. Required";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "namespace is the namespace of the service. Required";
          type = types.str;
        };
        "path" = mkOption {
          description = "path is an optional URL path at which the webhook will be contacted.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is an optional service port at which the webhook will be contacted. `port` should be a valid port number (1-65535, inclusive). Defaults to 443 for backward compatibility.";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ValidationRule" = {

      options = {
        "message" = mkOption {
          description = "Message represents the message displayed when validation fails. The message is required if the Rule contains line breaks. The message must not contain line breaks. If unset, the message is \"failed rule: {Rule}\". e.g. \"must be a URL with the host matching spec.host\"";
          type = (types.nullOr types.str);
        };
        "rule" = mkOption {
          description = "Rule represents the expression which will be evaluated by CEL. ref: https://github.com/google/cel-spec The Rule is scoped to the location of the x-kubernetes-validations extension in the schema. The `self` variable in the CEL expression is bound to the scoped value. Example: - Rule scoped to the root of a resource with a status subresource: {\"rule\": \"self.status.actual <= self.spec.maxDesired\"}\n\nIf the Rule is scoped to an object with properties, the accessible properties of the object are field selectable via `self.field` and field presence can be checked via `has(self.field)`. Null valued fields are treated as absent fields in CEL expressions. If the Rule is scoped to an object with additionalProperties (i.e. a map) the value of the map are accessible via `self[mapKey]`, map containment can be checked via `mapKey in self` and all entries of the map are accessible via CEL macros and functions such as `self.all(...)`. If the Rule is scoped to an array, the elements of the array are accessible via `self[i]` and also by macros and functions. If the Rule is scoped to a scalar, `self` is bound to the scalar value. Examples: - Rule scoped to a map of objects: {\"rule\": \"self.components['Widget'].priority < 10\"} - Rule scoped to a list of integers: {\"rule\": \"self.values.all(value, value >= 0 && value < 100)\"} - Rule scoped to a string value: {\"rule\": \"self.startsWith('kube')\"}\n\nThe `apiVersion`, `kind`, `metadata.name` and `metadata.generateName` are always accessible from the root of the object and from any x-kubernetes-embedded-resource annotated objects. No other metadata properties are accessible.\n\nUnknown data preserved in custom resources via x-kubernetes-preserve-unknown-fields is not accessible in CEL expressions. This includes: - Unknown field values that are preserved by object schemas with x-kubernetes-preserve-unknown-fields. - Object properties where the property schema is of an \"unknown type\". An \"unknown type\" is recursively defined as:\n  - A schema with no type and x-kubernetes-preserve-unknown-fields set to true\n  - An array where the items schema is of an \"unknown type\"\n  - An object where the additionalProperties schema is of an \"unknown type\"\n\nOnly property names of the form `[a-zA-Z_.-/][a-zA-Z0-9_.-/]*` are accessible. Accessible property names are escaped according to the following rules when accessed in the expression: - '__' escapes to '__underscores__' - '.' escapes to '__dot__' - '-' escapes to '__dash__' - '/' escapes to '__slash__' - Property names that exactly match a CEL RESERVED keyword escape to '__{keyword}__'. The keywords are:\n\t  \"true\", \"false\", \"null\", \"in\", \"as\", \"break\", \"const\", \"continue\", \"else\", \"for\", \"function\", \"if\",\n\t  \"import\", \"let\", \"loop\", \"package\", \"namespace\", \"return\".\nExamples:\n  - Rule accessing a property named \"namespace\": {\"rule\": \"self.__namespace__ > 0\"}\n  - Rule accessing a property named \"x-prop\": {\"rule\": \"self.x__dash__prop > 0\"}\n  - Rule accessing a property named \"redact__d\": {\"rule\": \"self.redact__underscores__d > 0\"}\n\nEquality on arrays with x-kubernetes-list-type of 'set' or 'map' ignores element order, i.e. [1, 2] == [2, 1]. Concatenation on arrays with x-kubernetes-list-type use the semantics of the list type:\n  - 'set': `X + Y` performs a union where the array positions of all elements in `X` are preserved and\n    non-intersecting elements in `Y` are appended, retaining their partial order.\n  - 'map': `X + Y` performs a merge where the array positions of all keys in `X` are preserved but the values\n    are overwritten by values in `Y` when the key sets of `X` and `Y` intersect. Elements in `Y` with\n    non-intersecting keys are appended, retaining their partial order.";
          type = types.str;
        };
      };


      config = {
        "message" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.WebhookClientConfig" = {

      options = {
        "caBundle" = mkOption {
          description = "caBundle is a PEM encoded CA bundle which will be used to validate the webhook's server certificate. If unspecified, system trust roots on the apiserver are used.";
          type = (types.nullOr types.str);
        };
        "service" = mkOption {
          description = "service is a reference to the service for this webhook. Either service or url must be specified.\n\nIf the webhook is running within the cluster, then you should use `service`.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.ServiceReference"));
        };
        "url" = mkOption {
          description = "url gives the location of the webhook, in standard URL form (`scheme://host:port/path`). Exactly one of `url` or `service` must be specified.\n\nThe `host` should not refer to a service running in the cluster; use the `service` field instead. The host might be resolved via external DNS in some apiservers (e.g., `kube-apiserver` cannot resolve in-cluster DNS as that would be a layering violation). `host` may also be an IP address.\n\nPlease note that using `localhost` or `127.0.0.1` as a `host` is risky unless you take great care to run this webhook on all hosts which run an apiserver which might need to make calls to this webhook. Such installs are likely to be non-portable, i.e., not easy to turn up in a new cluster.\n\nThe scheme must be \"https\"; the URL must begin with \"https://\".\n\nA path is optional, and if present may be any string permissible in a URL. You may use the path to pass an arbitrary string to the webhook, for example, a cluster identifier.\n\nAttempting to use a user or basic auth e.g. \"user:password@\" is not allowed. Fragments (\"#...\") and query parameters (\"?...\") are not allowed, either.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "caBundle" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
      };

    };
    "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.WebhookConversion" = {

      options = {
        "clientConfig" = mkOption {
          description = "clientConfig is the instructions for how to call the webhook if strategy is `Webhook`.";
          type = (types.nullOr (submoduleOf "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.WebhookClientConfig"));
        };
        "conversionReviewVersions" = mkOption {
          description = "conversionReviewVersions is an ordered list of preferred `ConversionReview` versions the Webhook expects. The API server will use the first version in the list which it supports. If none of the versions specified in this list are supported by API server, conversion will fail for the custom resource. If a persisted Webhook configuration specifies allowed versions and does not include any versions known to the API Server, calls to the webhook will fail.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "clientConfig" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.api.resource.Quantity" = { };
    "io.k8s.apimachinery.pkg.apis.meta.v1.APIGroup" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "name is the name of the group.";
          type = types.str;
        };
        "preferredVersion" = mkOption {
          description = "preferredVersion is the version preferred by the API server, which probably is the storage version.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.GroupVersionForDiscovery"));
        };
        "serverAddressByClientCIDRs" = mkOption {
          description = "a map of client CIDR to server address that is serving this group. This is to help clients reach servers in the most network-efficient way possible. Clients can use the appropriate server address as per the CIDR that they match. In case of multiple matches, clients should use the longest matching CIDR. The server returns only those CIDRs that it thinks that the client can match. For example: the master will return an internal IP CIDR only, if the client reaches the server using an internal IP. Server looks at X-Forwarded-For header or X-Real-Ip header or request.RemoteAddr (in that order) to get the client IP.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ServerAddressByClientCIDR")));
        };
        "versions" = mkOption {
          description = "versions are the versions supported in this group.";
          type = (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.GroupVersionForDiscovery"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "preferredVersion" = mkOverride 1002 null;
        "serverAddressByClientCIDRs" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.APIGroupList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "groups" = mkOption {
          description = "groups is a list of APIGroup.";
          type = (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.APIGroup"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.APIResource" = {

      options = {
        "categories" = mkOption {
          description = "categories is a list of the grouped resources this resource belongs to (e.g. 'all')";
          type = (types.nullOr (types.listOf types.str));
        };
        "group" = mkOption {
          description = "group is the preferred group of the resource.  Empty implies the group of the containing resource list. For subresources, this may have a different value, for example: Scale\".";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "kind is the kind for the resource (e.g. 'Foo' is the kind for a resource 'foo')";
          type = types.str;
        };
        "name" = mkOption {
          description = "name is the plural name of the resource.";
          type = types.str;
        };
        "namespaced" = mkOption {
          description = "namespaced indicates if a resource is namespaced or not.";
          type = types.bool;
        };
        "shortNames" = mkOption {
          description = "shortNames is a list of suggested short names of the resource.";
          type = (types.nullOr (types.listOf types.str));
        };
        "singularName" = mkOption {
          description = "singularName is the singular name of the resource.  This allows clients to handle plural and singular opaquely. The singularName is more correct for reporting status on a single item and both singular and plural are allowed from the kubectl CLI interface.";
          type = types.str;
        };
        "storageVersionHash" = mkOption {
          description = "The hash value of the storage version, the version this resource is converted to when written to the data store. Value must be treated as opaque by clients. Only equality comparison on the value is valid. This is an alpha feature and may change or be removed in the future. The field is populated by the apiserver only if the StorageVersionHash feature gate is enabled. This field will remain optional even if it graduates.";
          type = (types.nullOr types.str);
        };
        "verbs" = mkOption {
          description = "verbs is a list of supported kube verbs (this includes get, list, watch, create, update, patch, delete, deletecollection, and proxy)";
          type = (types.listOf types.str);
        };
        "version" = mkOption {
          description = "version is the preferred version of the resource.  Empty implies the version of the containing resource list For subresources, this may have a different value, for example: v1 (while inside a v1beta1 version of the core resource's group)\".";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "categories" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "shortNames" = mkOverride 1002 null;
        "storageVersionHash" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.APIResourceList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "groupVersion" = mkOption {
          description = "groupVersion is the group and version this APIResourceList is for.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "resources" = mkOption {
          description = "resources contains the name of the resources and if they are namespaced.";
          type = (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.APIResource"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.APIVersions" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "serverAddressByClientCIDRs" = mkOption {
          description = "a map of client CIDR to server address that is serving this group. This is to help clients reach servers in the most network-efficient way possible. Clients can use the appropriate server address as per the CIDR that they match. In case of multiple matches, clients should use the longest matching CIDR. The server returns only those CIDRs that it thinks that the client can match. For example: the master will return an internal IP CIDR only, if the client reaches the server using an internal IP. Server looks at X-Forwarded-For header or X-Real-Ip header or request.RemoteAddr (in that order) to get the client IP.";
          type = (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ServerAddressByClientCIDR"));
        };
        "versions" = mkOption {
          description = "versions are the api versions that are available.";
          type = (types.listOf types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.Condition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another. This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition. This may be an empty string.";
          type = types.str;
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon. For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date with respect to the current state of the instance.";
          type = (types.nullOr types.int);
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition. Producers of specific condition types may define expected values and meanings for this field, and whether the values are considered a guaranteed API. The value should be a CamelCase string. This field may not be empty.";
          type = types.str;
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = types.str;
        };
      };


      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.DeleteOptions" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "dryRun" = mkOption {
          description = "When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed";
          type = (types.nullOr (types.listOf types.str));
        };
        "gracePeriodSeconds" = mkOption {
          description = "The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately.";
          type = (types.nullOr types.int);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "orphanDependents" = mkOption {
          description = "Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the \"orphan\" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both.";
          type = (types.nullOr types.bool);
        };
        "preconditions" = mkOption {
          description = "Must be fulfilled before a deletion is carried out. If not possible, a 409 Conflict status will be returned.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.Preconditions"));
        };
        "propagationPolicy" = mkOption {
          description = "Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "dryRun" = mkOverride 1002 null;
        "gracePeriodSeconds" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "orphanDependents" = mkOverride 1002 null;
        "preconditions" = mkOverride 1002 null;
        "propagationPolicy" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1" = { };
    "io.k8s.apimachinery.pkg.apis.meta.v1.GroupVersionForDiscovery" = {

      options = {
        "groupVersion" = mkOption {
          description = "groupVersion specifies the API group and version in the form \"group/version\"";
          type = types.str;
        };
        "version" = mkOption {
          description = "version specifies the version in the form of \"version\". This is to save the clients the trouble of splitting the GroupVersion.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelectorRequirement")));
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is \"key\", the operator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };


      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelectorRequirement" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };


      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta" = {

      options = {
        "continue" = mkOption {
          description = "continue may be set if the user set a limit on the number of items returned, and indicates that the server has more data available. The value is opaque and may be used to issue another request to the endpoint that served this list to retrieve the next set of available objects. Continuing a consistent list may not be possible if the server configuration has changed or more than a few minutes have passed. The resourceVersion field returned when using this continue value will be identical to the value in the first response, unless you have received this token from an error message.";
          type = (types.nullOr types.str);
        };
        "remainingItemCount" = mkOption {
          description = "remainingItemCount is the number of subsequent items in the list which are not included in this list response. If the list request contained label or field selectors, then the number of remaining items is unknown and the field will be left unset and omitted during serialization. If the list is complete (either because it is not chunking or because this is the last chunk), then there are no more remaining items and this field will be left unset and omitted during serialization. Servers older than v1.15 do not set this field. The intended use of the remainingItemCount is *estimating* the size of a collection. Clients should not rely on the remainingItemCount to be set or to be exact.";
          type = (types.nullOr types.int);
        };
        "resourceVersion" = mkOption {
          description = "String that identifies the server's internal version of this object that can be used by clients to determine when objects have changed. Value must be treated as opaque by clients and passed unmodified back to the server. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency";
          type = (types.nullOr types.str);
        };
        "selfLink" = mkOption {
          description = "Deprecated: selfLink is a legacy read-only field that is no longer populated by the system.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "continue" = mkOverride 1002 null;
        "remainingItemCount" = mkOverride 1002 null;
        "resourceVersion" = mkOverride 1002 null;
        "selfLink" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.ManagedFieldsEntry" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the version of this resource that this field set applies to. The format is \"group/version\" just like the top-level APIVersion field. It is necessary to track the version of a field set because it cannot be automatically converted.";
          type = (types.nullOr types.str);
        };
        "fieldsType" = mkOption {
          description = "FieldsType is the discriminator for the different fields format and version. There is currently only one possible value: \"FieldsV1\"";
          type = (types.nullOr types.str);
        };
        "fieldsV1" = mkOption {
          description = "FieldsV1 holds the first JSON version format as described in the \"FieldsV1\" type.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1"));
        };
        "manager" = mkOption {
          description = "Manager is an identifier of the workflow managing these fields.";
          type = (types.nullOr types.str);
        };
        "operation" = mkOption {
          description = "Operation is the type of operation which lead to this ManagedFieldsEntry being created. The only valid values for this field are 'Apply' and 'Update'.";
          type = (types.nullOr types.str);
        };
        "subresource" = mkOption {
          description = "Subresource is the name of the subresource used to update that object, or empty string if the object was updated through the main resource. The value of this field is used to distinguish between managers, even if they share the same name. For example, a status update will be distinct from a regular update using the same manager name. Note that the APIVersion field is not related to the Subresource field and it always corresponds to the version of the main resource.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "Time is the timestamp of when the ManagedFields entry was added. The timestamp will also be updated if a field is added, the manager changes any of the owned fields value or removes a field. The timestamp does not update when a field is removed from the entry because another manager took it over.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "fieldsType" = mkOverride 1002 null;
        "fieldsV1" = mkOverride 1002 null;
        "manager" = mkOverride 1002 null;
        "operation" = mkOverride 1002 null;
        "subresource" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime" = { };
    "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta" = {

      options = {
        "annotations" = mkOption {
          description = "Annotations is an unstructured key value map stored with a resource that may be set by external tools to store and retrieve arbitrary metadata. They are not queryable and should be preserved when modifying objects. More info: http://kubernetes.io/docs/user-guide/annotations";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "creationTimestamp" = mkOption {
          description = "CreationTimestamp is a timestamp representing the server time when this object was created. It is not guaranteed to be set in happens-before order across separate operations. Clients may not set this value. It is represented in RFC3339 form and is in UTC.\n\nPopulated by the system. Read-only. Null for lists. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr types.str);
        };
        "deletionGracePeriodSeconds" = mkOption {
          description = "Number of seconds allowed for this object to gracefully terminate before it will be removed from the system. Only set when deletionTimestamp is also set. May only be shortened. Read-only.";
          type = (types.nullOr types.int);
        };
        "deletionTimestamp" = mkOption {
          description = "DeletionTimestamp is RFC 3339 date and time at which this resource will be deleted. This field is set by the server when a graceful deletion is requested by the user, and is not directly settable by a client. The resource is expected to be deleted (no longer visible from resource lists, and not reachable by name) after the time in this field, once the finalizers list is empty. As long as the finalizers list contains items, deletion is blocked. Once the deletionTimestamp is set, this value may not be unset or be set further into the future, although it may be shortened or the resource may be deleted prior to this time. For example, a user may request that a pod is deleted in 30 seconds. The Kubelet will react by sending a graceful termination signal to the containers in the pod. After that 30 seconds, the Kubelet will send a hard termination signal (SIGKILL) to the container and after cleanup, remove the pod from the API. In the presence of network partitions, this object may still exist after this timestamp, until an administrator or automated process can determine the resource is fully terminated. If not set, graceful deletion of the object has not been requested.\n\nPopulated by the system when a graceful deletion is requested. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr types.str);
        };
        "finalizers" = mkOption {
          description = "Must be empty before the object is deleted from the registry. Each entry is an identifier for the responsible component that will remove the entry from the list. If the deletionTimestamp of the object is non-nil, entries in this list can only be removed. Finalizers may be processed and removed in any order.  Order is NOT enforced because it introduces significant risk of stuck finalizers. finalizers is a shared field, any actor with permission can reorder it. If the finalizer list is processed in order, then this can lead to a situation in which the component responsible for the first finalizer in the list is waiting for a signal (field value, external system, or other) produced by a component responsible for a finalizer later in the list, resulting in a deadlock. Without enforced ordering finalizers are free to order amongst themselves and are not vulnerable to ordering changes in the list.";
          type = (types.nullOr (types.listOf types.str));
        };
        "generateName" = mkOption {
          description = "GenerateName is an optional prefix, used by the server, to generate a unique name ONLY IF the Name field has not been provided. If this field is used, the name returned to the client will be different than the name passed. This value will also be combined with a unique suffix. The provided value has the same validation rules as the Name field, and may be truncated by the length of the suffix required to make the value unique on the server.\n\nIf this field is specified and the generated name exists, the server will return a 409.\n\nApplied only if Name is not specified. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#idempotency";
          type = (types.nullOr types.str);
        };
        "generation" = mkOption {
          description = "A sequence number representing a specific generation of the desired state. Populated by the system. Read-only.";
          type = (types.nullOr types.int);
        };
        "labels" = mkOption {
          description = "Map of string keys and values that can be used to organize and categorize (scope and select) objects. May match selectors of replication controllers and services. More info: http://kubernetes.io/docs/user-guide/labels";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "managedFields" = mkOption {
          description = "ManagedFields maps workflow-id and version to the set of fields that are managed by that workflow. This is mostly for internal housekeeping, and users typically shouldn't need to set or understand this field. A workflow can be the user's name, a controller's name, or the name of a specific apply path like \"ci-cd\". The set of fields is always in the version that the workflow used when modifying the object.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ManagedFieldsEntry")));
        };
        "name" = mkOption {
          description = "Name must be unique within a namespace. Is required when creating resources, although some resources may allow a client to request the generation of an appropriate name automatically. Name is primarily intended for creation idempotence and configuration definition. Cannot be updated. More info: http://kubernetes.io/docs/user-guide/identifiers#names";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace defines the space within which each name must be unique. An empty namespace is equivalent to the \"default\" namespace, but \"default\" is the canonical representation. Not all objects are required to be scoped to a namespace - the value of this field for those objects will be empty.\n\nMust be a DNS_LABEL. Cannot be updated. More info: http://kubernetes.io/docs/user-guide/namespaces";
          type = (types.nullOr types.str);
        };
        "ownerReferences" = mkOption {
          description = "List of objects depended by this object. If ALL objects in the list have been deleted, this object will be garbage collected. If this object is managed by a controller, then an entry in this list will point to this controller, with the controller field set to true. There cannot be more than one managing controller.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.apimachinery.pkg.apis.meta.v1.OwnerReference" "uid"));
          apply = attrsToList;
        };
        "resourceVersion" = mkOption {
          description = "An opaque value that represents the internal version of this object that can be used by clients to determine when objects have changed. May be used for optimistic concurrency, change detection, and the watch operation on a resource or set of resources. Clients must treat these values as opaque and passed unmodified back to the server. They may only be valid for a particular resource or set of resources.\n\nPopulated by the system. Read-only. Value must be treated as opaque by clients and . More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency";
          type = (types.nullOr types.str);
        };
        "selfLink" = mkOption {
          description = "Deprecated: selfLink is a legacy read-only field that is no longer populated by the system.";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "UID is the unique in time and space value for this object. It is typically generated by the server on successful creation of a resource and is not allowed to change on PUT operations.\n\nPopulated by the system. Read-only. More info: http://kubernetes.io/docs/user-guide/identifiers#uids";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "annotations" = mkOverride 1002 null;
        "creationTimestamp" = mkOverride 1002 null;
        "deletionGracePeriodSeconds" = mkOverride 1002 null;
        "deletionTimestamp" = mkOverride 1002 null;
        "finalizers" = mkOverride 1002 null;
        "generateName" = mkOverride 1002 null;
        "generation" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "managedFields" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "ownerReferences" = mkOverride 1002 null;
        "resourceVersion" = mkOverride 1002 null;
        "selfLink" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.OwnerReference" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = types.str;
        };
        "blockOwnerDeletion" = mkOption {
          description = "If true, AND if the owner has the \"foregroundDeletion\" finalizer, then the owner cannot be deleted from the key-value store until this reference is removed. See https://kubernetes.io/docs/concepts/architecture/garbage-collection/#foreground-deletion for how the garbage collector interacts with this field and enforces the foreground deletion. Defaults to false. To set this field, a user needs \"delete\" permission of the owner, otherwise 422 (Unprocessable Entity) will be returned.";
          type = (types.nullOr types.bool);
        };
        "controller" = mkOption {
          description = "If true, this reference points to the managing controller.";
          type = (types.nullOr types.bool);
        };
        "kind" = mkOption {
          description = "Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent. More info: http://kubernetes.io/docs/user-guide/identifiers#names";
          type = types.str;
        };
        "uid" = mkOption {
          description = "UID of the referent. More info: http://kubernetes.io/docs/user-guide/identifiers#uids";
          type = types.str;
        };
      };


      config = {
        "blockOwnerDeletion" = mkOverride 1002 null;
        "controller" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.Patch" = { };
    "io.k8s.apimachinery.pkg.apis.meta.v1.Preconditions" = {

      options = {
        "resourceVersion" = mkOption {
          description = "Specifies the target ResourceVersion";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "Specifies the target UID.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "resourceVersion" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.ServerAddressByClientCIDR" = {

      options = {
        "clientCIDR" = mkOption {
          description = "The CIDR with which clients can match their IP to figure out the server address that they should use.";
          type = types.str;
        };
        "serverAddress" = mkOption {
          description = "Address of this server, suitable for a client that matches the above CIDR. This can be a hostname, hostname:port, IP or IP:port.";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.Status" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "code" = mkOption {
          description = "Suggested HTTP return code for this status, 0 if not set.";
          type = (types.nullOr types.int);
        };
        "details" = mkOption {
          description = "Extended data associated with the reason.  Each reason may define its own extended details. This field is optional and the data returned is not guaranteed to conform to any schema except that defined by the reason type.";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.StatusDetails"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable description of the status of this operation.";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
        "reason" = mkOption {
          description = "A machine-readable description of why this operation is in the \"Failure\" status. If this value is empty there is no information available. A Reason clarifies an HTTP status code but does not override it.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status of the operation. One of: \"Success\" or \"Failure\". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "code" = mkOverride 1002 null;
        "details" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.StatusCause" = {

      options = {
        "field" = mkOption {
          description = "The field of the resource that has caused this error, as named by its JSON serialization. May include dot and postfix notation for nested attributes. Arrays are zero-indexed.  Fields may appear more than once in an array of causes due to fields having multiple errors. Optional.\n\nExamples:\n  \"name\" - the field \"name\" on the current resource\n  \"items[0].name\" - the field \"name\" on the first array entry in \"items\"";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "A human-readable description of the cause of the error.  This field may be presented as-is to a reader.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "A machine-readable description of the cause of the error. If this value is empty there is no information available.";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "field" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.StatusDetails" = {

      options = {
        "causes" = mkOption {
          description = "The Causes array includes more details associated with the StatusReason failure. Not all StatusReasons may provide detailed causes.";
          type = (types.nullOr (types.listOf (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.StatusCause")));
        };
        "group" = mkOption {
          description = "The group attribute of the resource associated with the status StatusReason.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "The kind attribute of the resource associated with the status StatusReason. On some operations may differ from the requested resource Kind. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name attribute of the resource associated with the status StatusReason (when there is a single name which can be described).";
          type = (types.nullOr types.str);
        };
        "retryAfterSeconds" = mkOption {
          description = "If specified, the time in seconds before the operation should be retried. Some errors may indicate the client must take an alternate action - for those errors this field may indicate how long to wait before taking the alternate action.";
          type = (types.nullOr types.int);
        };
        "uid" = mkOption {
          description = "UID of the resource. (when there is a single resource which can be described). More info: http://kubernetes.io/docs/user-guide/identifiers#uids";
          type = (types.nullOr types.str);
        };
      };


      config = {
        "causes" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "retryAfterSeconds" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "io.k8s.apimachinery.pkg.apis.meta.v1.Time" = { };
    "io.k8s.apimachinery.pkg.apis.meta.v1.WatchEvent" = {

      options = {
        "object" = mkOption {
          description = "Object is:\n * If Type is Added or Modified: the new state of the object.\n * If Type is Deleted: the state of the object immediately before deletion.\n * If Type is Error: *Status is recommended; other types may make sense\n   depending on context.";
          type = (submoduleOf "io.k8s.apimachinery.pkg.runtime.RawExtension");
        };
        "type" = mkOption {
          description = "";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.apimachinery.pkg.runtime.RawExtension" = { };
    "io.k8s.apimachinery.pkg.util.intstr.IntOrString" = { };
    "io.k8s.apimachinery.pkg.version.Info" = {

      options = {
        "buildDate" = mkOption {
          description = "";
          type = types.str;
        };
        "compiler" = mkOption {
          description = "";
          type = types.str;
        };
        "gitCommit" = mkOption {
          description = "";
          type = types.str;
        };
        "gitTreeState" = mkOption {
          description = "";
          type = types.str;
        };
        "gitVersion" = mkOption {
          description = "";
          type = types.str;
        };
        "goVersion" = mkOption {
          description = "";
          type = types.str;
        };
        "major" = mkOption {
          description = "";
          type = types.str;
        };
        "minor" = mkOption {
          description = "";
          type = types.str;
        };
        "platform" = mkOption {
          description = "";
          type = types.str;
        };
      };


      config = { };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "Spec contains information for locating and communicating with a server";
          type = (types.nullOr (submoduleOf "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceSpec"));
        };
        "status" = mkOption {
          description = "Status contains derived information about an API server";
          type = (types.nullOr (submoduleOf "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceStatus"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceCondition" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "Last time the condition transitioned from one status to another.";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Human-readable message indicating details about last transition.";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "Unique, one-word, CamelCase reason for the condition's last transition.";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "Status is the status of the condition. Can be True, False, Unknown.";
          type = types.str;
        };
        "type" = mkOption {
          description = "Type is the type of the condition.";
          type = types.str;
        };
      };


      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
      };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceList" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "items" = mkOption {
          description = "Items is the list of APIService";
          type = (types.listOf (submoduleOf "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService"));
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard list metadata More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (submoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ListMeta"));
        };
      };


      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
      };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceSpec" = {

      options = {
        "caBundle" = mkOption {
          description = "CABundle is a PEM encoded CA bundle which will be used to validate an API server's serving certificate. If unspecified, system trust roots on the apiserver are used.";
          type = (types.nullOr types.str);
        };
        "group" = mkOption {
          description = "Group is the API group name this server hosts";
          type = (types.nullOr types.str);
        };
        "groupPriorityMinimum" = mkOption {
          description = "GroupPriorityMininum is the priority this group should have at least. Higher priority means that the group is preferred by clients over lower priority ones. Note that other versions of this group might specify even higher GroupPriorityMininum values such that the whole group gets a higher priority. The primary sort is based on GroupPriorityMinimum, ordered highest number to lowest (20 before 10). The secondary sort is based on the alphabetical comparison of the name of the object.  (v1.bar before v1.foo) We'd recommend something like: *.k8s.io (except extensions) at 18000 and PaaSes (OpenShift, Deis) are recommended to be in the 2000s";
          type = types.int;
        };
        "insecureSkipTLSVerify" = mkOption {
          description = "InsecureSkipTLSVerify disables TLS certificate verification when communicating with this server. This is strongly discouraged.  You should use the CABundle instead.";
          type = (types.nullOr types.bool);
        };
        "service" = mkOption {
          description = "Service is a reference to the service for this API server.  It must communicate on port 443. If the Service is nil, that means the handling for the API groupversion is handled locally on this server. The call will simply delegate to the normal handler chain to be fulfilled.";
          type = (types.nullOr (submoduleOf "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.ServiceReference"));
        };
        "version" = mkOption {
          description = "Version is the API version this server hosts.  For example, \"v1\"";
          type = (types.nullOr types.str);
        };
        "versionPriority" = mkOption {
          description = "VersionPriority controls the ordering of this API version inside of its group.  Must be greater than zero. The primary sort is based on VersionPriority, ordered highest to lowest (20 before 10). Since it's inside of a group, the number can be small, probably in the 10s. In case of equal version priorities, the version string will be used to compute the order inside a group. If the version string is \"kube-like\", it will sort above non \"kube-like\" version strings, which are ordered lexicographically. \"Kube-like\" versions start with a \"v\", then are followed by a number (the major version), then optionally the string \"alpha\" or \"beta\" and another number (the minor version). These are sorted first by GA > beta > alpha (where GA is a version with no suffix such as beta or alpha), and then by comparing major version, then minor version. An example sorted list of versions: v10, v2, v1, v11beta2, v10beta3, v3beta1, v12alpha1, v11alpha2, foo1, foo10.";
          type = types.int;
        };
      };


      config = {
        "caBundle" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "insecureSkipTLSVerify" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Current service state of apiService.";
          type = (types.nullOr (coerceAttrsOfSubmodulesToListByKey "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIServiceCondition" "type"));
          apply = attrsToList;
        };
      };


      config = {
        "conditions" = mkOverride 1002 null;
      };

    };
    "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.ServiceReference" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the service";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the service";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "If specified, the port on the service that hosting webhook. Default to 443 for backward compatibility. `port` should be a valid port number (1-65535, inclusive).";
          type = (types.nullOr types.int);
        };
      };


      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "admissionregistration.k8s.io"."v1"."MutatingWebhookConfiguration" = mkOption {
        description = "MutatingWebhookConfiguration describes the configuration of and admission webhook that accept or reject and may change the object.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1.MutatingWebhookConfiguration" "mutatingwebhookconfigurations" "MutatingWebhookConfiguration" "admissionregistration.k8s.io" "v1"));
        default = { };
      };
      "admissionregistration.k8s.io"."v1"."ValidatingWebhookConfiguration" = mkOption {
        description = "ValidatingWebhookConfiguration describes the configuration of and admission webhook that accept or reject and object without changing it.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1.ValidatingWebhookConfiguration" "validatingwebhookconfigurations" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io" "v1"));
        default = { };
      };
      "admissionregistration.k8s.io"."v1alpha1"."ValidatingAdmissionPolicy" = mkOption {
        description = "ValidatingAdmissionPolicy describes the definition of an admission validation policy that accepts or rejects an object without changing it.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicy" "validatingadmissionpolicies" "ValidatingAdmissionPolicy" "admissionregistration.k8s.io" "v1alpha1"));
        default = { };
      };
      "admissionregistration.k8s.io"."v1alpha1"."ValidatingAdmissionPolicyBinding" = mkOption {
        description = "ValidatingAdmissionPolicyBinding binds the ValidatingAdmissionPolicy with paramerized resources. ValidatingAdmissionPolicyBinding and parameter CRDs together define how cluster administrators configure policies for clusters.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBinding" "validatingadmissionpolicybindings" "ValidatingAdmissionPolicyBinding" "admissionregistration.k8s.io" "v1alpha1"));
        default = { };
      };
      "internal.apiserver.k8s.io"."v1alpha1"."StorageVersion" = mkOption {
        description = "Storage version of a specific resource.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apiserverinternal.v1alpha1.StorageVersion" "storageversions" "StorageVersion" "internal.apiserver.k8s.io" "v1alpha1"));
        default = { };
      };
      "apps"."v1"."ControllerRevision" = mkOption {
        description = "ControllerRevision implements an immutable snapshot of state data. Clients are responsible for serializing and deserializing the objects that contain their internal state. Once a ControllerRevision has been successfully created, it can not be updated. The API Server will fail validation of all requests that attempt to mutate the Data field. ControllerRevisions may, however, be deleted. Note that, due to its use by both the DaemonSet and StatefulSet controllers for update and rollback, this object is beta. However, it may be subject to name and representation changes in future releases, and clients should not depend on its stability. It is primarily for internal use by controllers.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.ControllerRevision" "controllerrevisions" "ControllerRevision" "apps" "v1"));
        default = { };
      };
      "apps"."v1"."DaemonSet" = mkOption {
        description = "DaemonSet represents the configuration of a daemon set.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.DaemonSet" "daemonsets" "DaemonSet" "apps" "v1"));
        default = { };
      };
      "apps"."v1"."Deployment" = mkOption {
        description = "Deployment enables declarative updates for Pods and ReplicaSets.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.Deployment" "deployments" "Deployment" "apps" "v1"));
        default = { };
      };
      "apps"."v1"."ReplicaSet" = mkOption {
        description = "ReplicaSet ensures that a specified number of pod replicas are running at any given time.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.ReplicaSet" "replicasets" "ReplicaSet" "apps" "v1"));
        default = { };
      };
      "apps"."v1"."StatefulSet" = mkOption {
        description = "StatefulSet represents a set of pods with consistent identities. Identities are defined as:\n  - Network: A single stable DNS and hostname.\n  - Storage: As many VolumeClaims as requested.\n\nThe StatefulSet guarantees that a given network identity will always map to the same storage identity.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.StatefulSet" "statefulsets" "StatefulSet" "apps" "v1"));
        default = { };
      };
      "authentication.k8s.io"."v1"."TokenRequest" = mkOption {
        description = "TokenRequest requests a token for a given service account.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1.TokenRequest" "token" "TokenRequest" "authentication.k8s.io" "v1"));
        default = { };
      };
      "authentication.k8s.io"."v1"."TokenReview" = mkOption {
        description = "TokenReview attempts to authenticate a token to a known user. Note: TokenReview requests may be cached by the webhook token authenticator plugin in the kube-apiserver.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1.TokenReview" "tokenreviews" "TokenReview" "authentication.k8s.io" "v1"));
        default = { };
      };
      "authentication.k8s.io"."v1alpha1"."SelfSubjectReview" = mkOption {
        description = "SelfSubjectReview contains the user information that the kube-apiserver has about the user making this request. When using impersonation, users will receive the user info of the user being impersonated.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1alpha1.SelfSubjectReview" "selfsubjectreviews" "SelfSubjectReview" "authentication.k8s.io" "v1alpha1"));
        default = { };
      };
      "authorization.k8s.io"."v1"."LocalSubjectAccessReview" = mkOption {
        description = "LocalSubjectAccessReview checks whether or not a user or group can perform an action in a given namespace. Having a namespace scoped resource makes it much easier to grant namespace scoped policy that includes permissions checking.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.LocalSubjectAccessReview" "localsubjectaccessreviews" "LocalSubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "authorization.k8s.io"."v1"."SelfSubjectAccessReview" = mkOption {
        description = "SelfSubjectAccessReview checks whether or the current user can perform an action.  Not filling in a spec.namespace means \"in all namespaces\".  Self is a special case, because users should always be able to check whether they can perform an action";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SelfSubjectAccessReview" "selfsubjectaccessreviews" "SelfSubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "authorization.k8s.io"."v1"."SelfSubjectRulesReview" = mkOption {
        description = "SelfSubjectRulesReview enumerates the set of actions the current user can perform within a namespace. The returned list of actions may be incomplete depending on the server's authorization mode, and any errors experienced during the evaluation. SelfSubjectRulesReview should be used by UIs to show/hide actions, or to quickly let an end user reason about their permissions. It should NOT Be used by external systems to drive authorization decisions as this raises confused deputy, cache lifetime/revocation, and correctness concerns. SubjectAccessReview, and LocalAccessReview are the correct way to defer authorization decisions to the API server.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SelfSubjectRulesReview" "selfsubjectrulesreviews" "SelfSubjectRulesReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "authorization.k8s.io"."v1"."SubjectAccessReview" = mkOption {
        description = "SubjectAccessReview checks whether or not a user or group can perform an action.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SubjectAccessReview" "subjectaccessreviews" "SubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "autoscaling"."v1"."HorizontalPodAutoscaler" = mkOption {
        description = "configuration of a horizontal pod autoscaler.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.autoscaling.v1.HorizontalPodAutoscaler" "horizontalpodautoscalers" "HorizontalPodAutoscaler" "autoscaling" "v1"));
        default = { };
      };
      "autoscaling"."v2"."HorizontalPodAutoscaler" = mkOption {
        description = "HorizontalPodAutoscaler is the configuration for a horizontal pod autoscaler, which automatically manages the replica count of any resource implementing the scale subresource based on the metrics specified.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.autoscaling.v2.HorizontalPodAutoscaler" "horizontalpodautoscalers" "HorizontalPodAutoscaler" "autoscaling" "v2"));
        default = { };
      };
      "batch"."v1"."CronJob" = mkOption {
        description = "CronJob represents the configuration of a single cron job.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.batch.v1.CronJob" "cronjobs" "CronJob" "batch" "v1"));
        default = { };
      };
      "batch"."v1"."Job" = mkOption {
        description = "Job represents the configuration of a single job.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.batch.v1.Job" "jobs" "Job" "batch" "v1"));
        default = { };
      };
      "certificates.k8s.io"."v1"."CertificateSigningRequest" = mkOption {
        description = "CertificateSigningRequest objects provide a mechanism to obtain x509 certificates by submitting a certificate signing request, and having it asynchronously approved and issued.\n\nKubelets use this API to obtain:\n 1. client certificates to authenticate to kube-apiserver (with the \"kubernetes.io/kube-apiserver-client-kubelet\" signerName).\n 2. serving certificates for TLS endpoints kube-apiserver can connect to securely (with the \"kubernetes.io/kubelet-serving\" signerName).\n\nThis API can be used to request client certificates to authenticate to kube-apiserver (with the \"kubernetes.io/kube-apiserver-client\" signerName), or to obtain certificates from custom non-Kubernetes signers.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.certificates.v1.CertificateSigningRequest" "certificatesigningrequests" "CertificateSigningRequest" "certificates.k8s.io" "v1"));
        default = { };
      };
      "coordination.k8s.io"."v1"."Lease" = mkOption {
        description = "Lease defines a lease concept.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.coordination.v1.Lease" "leases" "Lease" "coordination.k8s.io" "v1"));
        default = { };
      };
      "core"."v1"."Binding" = mkOption {
        description = "Binding ties one object to another; for example, a pod is bound to a node by a scheduler. Deprecated in 1.7, please use the bindings subresource of pods instead.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Binding" "bindings" "Binding" "core" "v1"));
        default = { };
      };
      "core"."v1"."ConfigMap" = mkOption {
        description = "ConfigMap holds configuration data for pods to consume.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ConfigMap" "configmaps" "ConfigMap" "core" "v1"));
        default = { };
      };
      "core"."v1"."Endpoints" = mkOption {
        description = "Endpoints is a collection of endpoints that implement the actual service. Example:\n\n\t Name: \"mysvc\",\n\t Subsets: [\n\t   {\n\t     Addresses: [{\"ip\": \"10.10.1.1\"}, {\"ip\": \"10.10.2.2\"}],\n\t     Ports: [{\"name\": \"a\", \"port\": 8675}, {\"name\": \"b\", \"port\": 309}]\n\t   },\n\t   {\n\t     Addresses: [{\"ip\": \"10.10.3.3\"}],\n\t     Ports: [{\"name\": \"a\", \"port\": 93}, {\"name\": \"b\", \"port\": 76}]\n\t   },\n\t]";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Endpoints" "endpoints" "Endpoints" "core" "v1"));
        default = { };
      };
      "core"."v1"."Event" = mkOption {
        description = "Event is a report of an event somewhere in the cluster.  Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Event" "events" "Event" "core" "v1"));
        default = { };
      };
      "core"."v1"."LimitRange" = mkOption {
        description = "LimitRange sets resource usage limits for each kind of resource in a Namespace.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.LimitRange" "limitranges" "LimitRange" "core" "v1"));
        default = { };
      };
      "core"."v1"."Namespace" = mkOption {
        description = "Namespace provides a scope for Names. Use of multiple namespaces is optional.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Namespace" "namespaces" "Namespace" "core" "v1"));
        default = { };
      };
      "core"."v1"."Node" = mkOption {
        description = "Node is a worker node in Kubernetes. Each node will have a unique identifier in the cache (i.e. in etcd).";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Node" "nodes" "Node" "core" "v1"));
        default = { };
      };
      "core"."v1"."PersistentVolume" = mkOption {
        description = "PersistentVolume (PV) is a storage resource provisioned by an administrator. It is analogous to a node. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PersistentVolume" "persistentvolumes" "PersistentVolume" "core" "v1"));
        default = { };
      };
      "core"."v1"."PersistentVolumeClaim" = mkOption {
        description = "PersistentVolumeClaim is a user's request for and claim to a persistent volume";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PersistentVolumeClaim" "persistentvolumeclaims" "PersistentVolumeClaim" "core" "v1"));
        default = { };
      };
      "core"."v1"."Pod" = mkOption {
        description = "Pod is a collection of containers that can run on a host. This resource is created by clients and scheduled onto hosts.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Pod" "pods" "Pod" "core" "v1"));
        default = { };
      };
      "core"."v1"."PodTemplate" = mkOption {
        description = "PodTemplate describes a template for creating copies of a predefined pod.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PodTemplate" "podtemplates" "PodTemplate" "core" "v1"));
        default = { };
      };
      "core"."v1"."ReplicationController" = mkOption {
        description = "ReplicationController represents the configuration of a replication controller.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ReplicationController" "replicationcontrollers" "ReplicationController" "core" "v1"));
        default = { };
      };
      "core"."v1"."ResourceQuota" = mkOption {
        description = "ResourceQuota sets aggregate quota restrictions enforced per namespace";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ResourceQuota" "resourcequotas" "ResourceQuota" "core" "v1"));
        default = { };
      };
      "core"."v1"."Secret" = mkOption {
        description = "Secret holds secret data of a certain type. The total bytes of the values in the Data field must be less than MaxSecretSize bytes.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Secret" "secrets" "Secret" "core" "v1"));
        default = { };
      };
      "core"."v1"."Service" = mkOption {
        description = "Service is a named abstraction of software service (for example, mysql) consisting of local port (for example 3306) that the proxy listens on, and the selector that determines which pods will answer requests sent through the proxy.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Service" "services" "Service" "core" "v1"));
        default = { };
      };
      "core"."v1"."ServiceAccount" = mkOption {
        description = "ServiceAccount binds together: * a name, understood by users, and perhaps by peripheral systems, for an identity * a principal that can be authenticated and authorized * a set of secrets";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ServiceAccount" "serviceaccounts" "ServiceAccount" "core" "v1"));
        default = { };
      };
      "discovery.k8s.io"."v1"."EndpointSlice" = mkOption {
        description = "EndpointSlice represents a subset of the endpoints that implement a service. For a given service there may be multiple EndpointSlice objects, selected by labels, which must be joined to produce the full set of endpoints.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.discovery.v1.EndpointSlice" "endpointslices" "EndpointSlice" "discovery.k8s.io" "v1"));
        default = { };
      };
      "events.k8s.io"."v1"."Event" = mkOption {
        description = "Event is a report of an event somewhere in the cluster. It generally denotes some state change in the system. Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.events.v1.Event" "events" "Event" "events.k8s.io" "v1"));
        default = { };
      };
      "flowcontrol.apiserver.k8s.io"."v1beta2"."FlowSchema" = mkOption {
        description = "FlowSchema defines the schema of a group of flows. Note that a flow is made up of a set of inbound API requests with similar attributes and is identified by a pair of strings: the name of the FlowSchema and a \"flow distinguisher\".";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta2.FlowSchema" "flowschemas" "FlowSchema" "flowcontrol.apiserver.k8s.io" "v1beta2"));
        default = { };
      };
      "flowcontrol.apiserver.k8s.io"."v1beta2"."PriorityLevelConfiguration" = mkOption {
        description = "PriorityLevelConfiguration represents the configuration of a priority level.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta2.PriorityLevelConfiguration" "prioritylevelconfigurations" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io" "v1beta2"));
        default = { };
      };
      "flowcontrol.apiserver.k8s.io"."v1beta3"."FlowSchema" = mkOption {
        description = "FlowSchema defines the schema of a group of flows. Note that a flow is made up of a set of inbound API requests with similar attributes and is identified by a pair of strings: the name of the FlowSchema and a \"flow distinguisher\".";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta3.FlowSchema" "flowschemas" "FlowSchema" "flowcontrol.apiserver.k8s.io" "v1beta3"));
        default = { };
      };
      "flowcontrol.apiserver.k8s.io"."v1beta3"."PriorityLevelConfiguration" = mkOption {
        description = "PriorityLevelConfiguration represents the configuration of a priority level.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfiguration" "prioritylevelconfigurations" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io" "v1beta3"));
        default = { };
      };
      "networking.k8s.io"."v1"."Ingress" = mkOption {
        description = "Ingress is a collection of rules that allow inbound connections to reach the endpoints defined by a backend. An Ingress can be configured to give services externally-reachable urls, load balance traffic, terminate SSL, offer name based virtual hosting etc.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.Ingress" "ingresses" "Ingress" "networking.k8s.io" "v1"));
        default = { };
      };
      "networking.k8s.io"."v1"."IngressClass" = mkOption {
        description = "IngressClass represents the class of the Ingress, referenced by the Ingress Spec. The `ingressclass.kubernetes.io/is-default-class` annotation can be used to indicate that an IngressClass should be considered default. When a single IngressClass resource has this annotation set to true, new Ingress resources without a class specified will be assigned this default class.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.IngressClass" "ingressclasses" "IngressClass" "networking.k8s.io" "v1"));
        default = { };
      };
      "networking.k8s.io"."v1"."NetworkPolicy" = mkOption {
        description = "NetworkPolicy describes what network traffic is allowed for a set of Pods";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.NetworkPolicy" "networkpolicies" "NetworkPolicy" "networking.k8s.io" "v1"));
        default = { };
      };
      "networking.k8s.io"."v1alpha1"."ClusterCIDR" = mkOption {
        description = "ClusterCIDR represents a single configuration for per-Node Pod CIDR allocations when the MultiCIDRRangeAllocator is enabled (see the config for kube-controller-manager).  A cluster may have any number of ClusterCIDR resources, all of which will be considered when allocating a CIDR for a Node.  A ClusterCIDR is eligible to be used for a given Node when the node selector matches the node in question and has free CIDRs to allocate.  In case of multiple matching ClusterCIDR resources, the allocator will attempt to break ties using internal heuristics, but any ClusterCIDR whose node selector matches the Node may be used.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1alpha1.ClusterCIDR" "clustercidrs" "ClusterCIDR" "networking.k8s.io" "v1alpha1"));
        default = { };
      };
      "node.k8s.io"."v1"."RuntimeClass" = mkOption {
        description = "RuntimeClass defines a class of container runtime supported in the cluster. The RuntimeClass is used to determine which container runtime is used to run all containers in a pod. RuntimeClasses are manually defined by a user or cluster provisioner, and referenced in the PodSpec. The Kubelet is responsible for resolving the RuntimeClassName reference before running the pod.  For more details, see https://kubernetes.io/docs/concepts/containers/runtime-class/";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.node.v1.RuntimeClass" "runtimeclasses" "RuntimeClass" "node.k8s.io" "v1"));
        default = { };
      };
      "policy"."v1"."Eviction" = mkOption {
        description = "Eviction evicts a pod from its node subject to certain policies and safety constraints. This is a subresource of Pod.  A request to cause such an eviction is created by POSTing to .../pods/<pod name>/evictions.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.policy.v1.Eviction" "eviction" "Eviction" "policy" "v1"));
        default = { };
      };
      "policy"."v1"."PodDisruptionBudget" = mkOption {
        description = "PodDisruptionBudget is an object to define the max disruption that can be caused to a collection of pods";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.policy.v1.PodDisruptionBudget" "poddisruptionbudgets" "PodDisruptionBudget" "policy" "v1"));
        default = { };
      };
      "rbac.authorization.k8s.io"."v1"."ClusterRole" = mkOption {
        description = "ClusterRole is a cluster level, logical grouping of PolicyRules that can be referenced as a unit by a RoleBinding or ClusterRoleBinding.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.ClusterRole" "clusterroles" "ClusterRole" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "rbac.authorization.k8s.io"."v1"."ClusterRoleBinding" = mkOption {
        description = "ClusterRoleBinding references a ClusterRole, but not contain it.  It can reference a ClusterRole in the global namespace, and adds who information via Subject.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.ClusterRoleBinding" "clusterrolebindings" "ClusterRoleBinding" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "rbac.authorization.k8s.io"."v1"."Role" = mkOption {
        description = "Role is a namespaced, logical grouping of PolicyRules that can be referenced as a unit by a RoleBinding.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.Role" "roles" "Role" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "rbac.authorization.k8s.io"."v1"."RoleBinding" = mkOption {
        description = "RoleBinding references a role, but does not contain it.  It can reference a Role in the same namespace or a ClusterRole in the global namespace. It adds who information via Subjects and namespace information by which namespace it exists in.  RoleBindings in a given namespace only have effect in that namespace.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.RoleBinding" "rolebindings" "RoleBinding" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "resource.k8s.io"."v1alpha1"."PodScheduling" = mkOption {
        description = "PodScheduling objects hold information that is needed to schedule a Pod with ResourceClaims that use \"WaitForFirstConsumer\" allocation mode.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.PodScheduling" "podschedulings" "PodScheduling" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resource.k8s.io"."v1alpha1"."ResourceClaim" = mkOption {
        description = "ResourceClaim describes which resources are needed by a resource consumer. Its status tracks whether the resource has been allocated and what the resulting attributes are.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClaim" "resourceclaims" "ResourceClaim" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resource.k8s.io"."v1alpha1"."ResourceClaimTemplate" = mkOption {
        description = "ResourceClaimTemplate is used to produce ResourceClaim objects.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClaimTemplate" "resourceclaimtemplates" "ResourceClaimTemplate" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resource.k8s.io"."v1alpha1"."ResourceClass" = mkOption {
        description = "ResourceClass is used by administrators to influence how resources are allocated.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClass" "resourceclasses" "ResourceClass" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "scheduling.k8s.io"."v1"."PriorityClass" = mkOption {
        description = "PriorityClass defines mapping from a priority class name to the priority integer value. The value can be any valid integer.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.scheduling.v1.PriorityClass" "priorityclasses" "PriorityClass" "scheduling.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1"."CSIDriver" = mkOption {
        description = "CSIDriver captures information about a Container Storage Interface (CSI) volume driver deployed on the cluster. Kubernetes attach detach controller uses this object to determine whether attach is required. Kubelet uses this object to determine whether pod information needs to be passed on mount. CSIDriver objects are non-namespaced.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSIDriver" "csidrivers" "CSIDriver" "storage.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1"."CSINode" = mkOption {
        description = "CSINode holds information about all CSI drivers installed on a node. CSI drivers do not need to create the CSINode object directly. As long as they use the node-driver-registrar sidecar container, the kubelet will automatically populate the CSINode object for the CSI driver as part of kubelet plugin registration. CSINode has the same name as a node. If the object is missing, it means either there are no CSI Drivers available on the node, or the Kubelet version is low enough that it doesn't create this object. CSINode has an OwnerReference that points to the corresponding node object.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSINode" "csinodes" "CSINode" "storage.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1"."CSIStorageCapacity" = mkOption {
        description = "CSIStorageCapacity stores the result of one CSI GetCapacity call. For a given StorageClass, this describes the available capacity in a particular topology segment.  This can be used when considering where to instantiate new PersistentVolumes.\n\nFor example this can express things like: - StorageClass \"standard\" has \"1234 GiB\" available in \"topology.kubernetes.io/zone=us-east1\" - StorageClass \"localssd\" has \"10 GiB\" available in \"kubernetes.io/hostname=knode-abc123\"\n\nThe following three cases all imply that no capacity is available for a certain combination: - no object exists with suitable topology and storage class name - such an object exists, but the capacity is unset - such an object exists, but the capacity is zero\n\nThe producer of these objects can decide which approach is more suitable.\n\nThey are consumed by the kube-scheduler when a CSI driver opts into capacity-aware scheduling with CSIDriverSpec.StorageCapacity. The scheduler compares the MaximumVolumeSize against the requested size of pending volumes to filter out unsuitable nodes. If MaximumVolumeSize is unset, it falls back to a comparison against the less precise Capacity. If that is also unset, the scheduler assumes that capacity is insufficient and tries some other node.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSIStorageCapacity" "csistoragecapacities" "CSIStorageCapacity" "storage.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1"."StorageClass" = mkOption {
        description = "StorageClass describes the parameters for a class of storage for which PersistentVolumes can be dynamically provisioned.\n\nStorageClasses are non-namespaced; the name of the storage class according to etcd is in ObjectMeta.Name.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.StorageClass" "storageclasses" "StorageClass" "storage.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1"."VolumeAttachment" = mkOption {
        description = "VolumeAttachment captures the intent to attach or detach the specified volume to/from the specified node.\n\nVolumeAttachment objects are non-namespaced.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.VolumeAttachment" "volumeattachments" "VolumeAttachment" "storage.k8s.io" "v1"));
        default = { };
      };
      "storage.k8s.io"."v1beta1"."CSIStorageCapacity" = mkOption {
        description = "CSIStorageCapacity stores the result of one CSI GetCapacity call. For a given StorageClass, this describes the available capacity in a particular topology segment.  This can be used when considering where to instantiate new PersistentVolumes.\n\nFor example this can express things like: - StorageClass \"standard\" has \"1234 GiB\" available in \"topology.kubernetes.io/zone=us-east1\" - StorageClass \"localssd\" has \"10 GiB\" available in \"kubernetes.io/hostname=knode-abc123\"\n\nThe following three cases all imply that no capacity is available for a certain combination: - no object exists with suitable topology and storage class name - such an object exists, but the capacity is unset - such an object exists, but the capacity is zero\n\nThe producer of these objects can decide which approach is more suitable.\n\nThey are consumed by the kube-scheduler when a CSI driver opts into capacity-aware scheduling with CSIDriverSpec.StorageCapacity. The scheduler compares the MaximumVolumeSize against the requested size of pending volumes to filter out unsuitable nodes. If MaximumVolumeSize is unset, it falls back to a comparison against the less precise Capacity. If that is also unset, the scheduler assumes that capacity is insufficient and tries some other node.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1beta1.CSIStorageCapacity" "csistoragecapacities" "CSIStorageCapacity" "storage.k8s.io" "v1beta1"));
        default = { };
      };
      "apiextensions.k8s.io"."v1"."CustomResourceDefinition" = mkOption {
        description = "CustomResourceDefinition represents a resource that should be exposed on the API server.  Its name MUST be in the format <.spec.name>.<.spec.group>.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition" "customresourcedefinitions" "CustomResourceDefinition" "apiextensions.k8s.io" "v1"));
        default = { };
      };
      "apiregistration.k8s.io"."v1"."APIService" = mkOption {
        description = "APIService represents a server for a particular GroupVersion. Name must be \"version.group\".";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService" "apiservices" "APIService" "apiregistration.k8s.io" "v1"));
        default = { };
      };

    } // {
      "APIServices" = mkOption {
        description = "APIService represents a server for a particular GroupVersion. Name must be \"version.group\".";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.kube-aggregator.pkg.apis.apiregistration.v1.APIService" "apiservices" "APIService" "apiregistration.k8s.io" "v1"));
        default = { };
      };
      "bindings" = mkOption {
        description = "Binding ties one object to another; for example, a pod is bound to a node by a scheduler. Deprecated in 1.7, please use the bindings subresource of pods instead.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Binding" "bindings" "Binding" "core" "v1"));
        default = { };
      };
      "cSIDrivers" = mkOption {
        description = "CSIDriver captures information about a Container Storage Interface (CSI) volume driver deployed on the cluster. Kubernetes attach detach controller uses this object to determine whether attach is required. Kubelet uses this object to determine whether pod information needs to be passed on mount. CSIDriver objects are non-namespaced.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSIDriver" "csidrivers" "CSIDriver" "storage.k8s.io" "v1"));
        default = { };
      };
      "cSINodes" = mkOption {
        description = "CSINode holds information about all CSI drivers installed on a node. CSI drivers do not need to create the CSINode object directly. As long as they use the node-driver-registrar sidecar container, the kubelet will automatically populate the CSINode object for the CSI driver as part of kubelet plugin registration. CSINode has the same name as a node. If the object is missing, it means either there are no CSI Drivers available on the node, or the Kubelet version is low enough that it doesn't create this object. CSINode has an OwnerReference that points to the corresponding node object.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSINode" "csinodes" "CSINode" "storage.k8s.io" "v1"));
        default = { };
      };
      "cSIStorageCapacities" = mkOption {
        description = "CSIStorageCapacity stores the result of one CSI GetCapacity call. For a given StorageClass, this describes the available capacity in a particular topology segment.  This can be used when considering where to instantiate new PersistentVolumes.\n\nFor example this can express things like: - StorageClass \"standard\" has \"1234 GiB\" available in \"topology.kubernetes.io/zone=us-east1\" - StorageClass \"localssd\" has \"10 GiB\" available in \"kubernetes.io/hostname=knode-abc123\"\n\nThe following three cases all imply that no capacity is available for a certain combination: - no object exists with suitable topology and storage class name - such an object exists, but the capacity is unset - such an object exists, but the capacity is zero\n\nThe producer of these objects can decide which approach is more suitable.\n\nThey are consumed by the kube-scheduler when a CSI driver opts into capacity-aware scheduling with CSIDriverSpec.StorageCapacity. The scheduler compares the MaximumVolumeSize against the requested size of pending volumes to filter out unsuitable nodes. If MaximumVolumeSize is unset, it falls back to a comparison against the less precise Capacity. If that is also unset, the scheduler assumes that capacity is insufficient and tries some other node.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.CSIStorageCapacity" "csistoragecapacities" "CSIStorageCapacity" "storage.k8s.io" "v1"));
        default = { };
      };
      "certificateSigningRequests" = mkOption {
        description = "CertificateSigningRequest objects provide a mechanism to obtain x509 certificates by submitting a certificate signing request, and having it asynchronously approved and issued.\n\nKubelets use this API to obtain:\n 1. client certificates to authenticate to kube-apiserver (with the \"kubernetes.io/kube-apiserver-client-kubelet\" signerName).\n 2. serving certificates for TLS endpoints kube-apiserver can connect to securely (with the \"kubernetes.io/kubelet-serving\" signerName).\n\nThis API can be used to request client certificates to authenticate to kube-apiserver (with the \"kubernetes.io/kube-apiserver-client\" signerName), or to obtain certificates from custom non-Kubernetes signers.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.certificates.v1.CertificateSigningRequest" "certificatesigningrequests" "CertificateSigningRequest" "certificates.k8s.io" "v1"));
        default = { };
      };
      "clusterCIDRs" = mkOption {
        description = "ClusterCIDR represents a single configuration for per-Node Pod CIDR allocations when the MultiCIDRRangeAllocator is enabled (see the config for kube-controller-manager).  A cluster may have any number of ClusterCIDR resources, all of which will be considered when allocating a CIDR for a Node.  A ClusterCIDR is eligible to be used for a given Node when the node selector matches the node in question and has free CIDRs to allocate.  In case of multiple matching ClusterCIDR resources, the allocator will attempt to break ties using internal heuristics, but any ClusterCIDR whose node selector matches the Node may be used.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1alpha1.ClusterCIDR" "clustercidrs" "ClusterCIDR" "networking.k8s.io" "v1alpha1"));
        default = { };
      };
      "clusterRoles" = mkOption {
        description = "ClusterRole is a cluster level, logical grouping of PolicyRules that can be referenced as a unit by a RoleBinding or ClusterRoleBinding.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.ClusterRole" "clusterroles" "ClusterRole" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "clusterRoleBindings" = mkOption {
        description = "ClusterRoleBinding references a ClusterRole, but not contain it.  It can reference a ClusterRole in the global namespace, and adds who information via Subject.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.ClusterRoleBinding" "clusterrolebindings" "ClusterRoleBinding" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "configMaps" = mkOption {
        description = "ConfigMap holds configuration data for pods to consume.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ConfigMap" "configmaps" "ConfigMap" "core" "v1"));
        default = { };
      };
      "controllerRevisions" = mkOption {
        description = "ControllerRevision implements an immutable snapshot of state data. Clients are responsible for serializing and deserializing the objects that contain their internal state. Once a ControllerRevision has been successfully created, it can not be updated. The API Server will fail validation of all requests that attempt to mutate the Data field. ControllerRevisions may, however, be deleted. Note that, due to its use by both the DaemonSet and StatefulSet controllers for update and rollback, this object is beta. However, it may be subject to name and representation changes in future releases, and clients should not depend on its stability. It is primarily for internal use by controllers.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.ControllerRevision" "controllerrevisions" "ControllerRevision" "apps" "v1"));
        default = { };
      };
      "cronJobs" = mkOption {
        description = "CronJob represents the configuration of a single cron job.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.batch.v1.CronJob" "cronjobs" "CronJob" "batch" "v1"));
        default = { };
      };
      "customResourceDefinitions" = mkOption {
        description = "CustomResourceDefinition represents a resource that should be exposed on the API server.  Its name MUST be in the format <.spec.name>.<.spec.group>.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.CustomResourceDefinition" "customresourcedefinitions" "CustomResourceDefinition" "apiextensions.k8s.io" "v1"));
        default = { };
      };
      "daemonSets" = mkOption {
        description = "DaemonSet represents the configuration of a daemon set.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.DaemonSet" "daemonsets" "DaemonSet" "apps" "v1"));
        default = { };
      };
      "deployments" = mkOption {
        description = "Deployment enables declarative updates for Pods and ReplicaSets.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.Deployment" "deployments" "Deployment" "apps" "v1"));
        default = { };
      };
      "endpointSlices" = mkOption {
        description = "EndpointSlice represents a subset of the endpoints that implement a service. For a given service there may be multiple EndpointSlice objects, selected by labels, which must be joined to produce the full set of endpoints.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.discovery.v1.EndpointSlice" "endpointslices" "EndpointSlice" "discovery.k8s.io" "v1"));
        default = { };
      };
      "endpoints" = mkOption {
        description = "Endpoints is a collection of endpoints that implement the actual service. Example:\n\n\t Name: \"mysvc\",\n\t Subsets: [\n\t   {\n\t     Addresses: [{\"ip\": \"10.10.1.1\"}, {\"ip\": \"10.10.2.2\"}],\n\t     Ports: [{\"name\": \"a\", \"port\": 8675}, {\"name\": \"b\", \"port\": 309}]\n\t   },\n\t   {\n\t     Addresses: [{\"ip\": \"10.10.3.3\"}],\n\t     Ports: [{\"name\": \"a\", \"port\": 93}, {\"name\": \"b\", \"port\": 76}]\n\t   },\n\t]";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Endpoints" "endpoints" "Endpoints" "core" "v1"));
        default = { };
      };
      "events" = mkOption {
        description = "Event is a report of an event somewhere in the cluster.  Events have a limited retention time and triggers and messages may evolve with time.  Event consumers should not rely on the timing of an event with a given Reason reflecting a consistent underlying trigger, or the continued existence of events with that Reason.  Events should be treated as informative, best-effort, supplemental data.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Event" "events" "Event" "core" "v1"));
        default = { };
      };
      "eviction" = mkOption {
        description = "Eviction evicts a pod from its node subject to certain policies and safety constraints. This is a subresource of Pod.  A request to cause such an eviction is created by POSTing to .../pods/<pod name>/evictions.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.policy.v1.Eviction" "eviction" "Eviction" "policy" "v1"));
        default = { };
      };
      "flowSchemas" = mkOption {
        description = "FlowSchema defines the schema of a group of flows. Note that a flow is made up of a set of inbound API requests with similar attributes and is identified by a pair of strings: the name of the FlowSchema and a \"flow distinguisher\".";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta3.FlowSchema" "flowschemas" "FlowSchema" "flowcontrol.apiserver.k8s.io" "v1beta3"));
        default = { };
      };
      "horizontalPodAutoscalers" = mkOption {
        description = "HorizontalPodAutoscaler is the configuration for a horizontal pod autoscaler, which automatically manages the replica count of any resource implementing the scale subresource based on the metrics specified.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.autoscaling.v2.HorizontalPodAutoscaler" "horizontalpodautoscalers" "HorizontalPodAutoscaler" "autoscaling" "v2"));
        default = { };
      };
      "ingresses" = mkOption {
        description = "Ingress is a collection of rules that allow inbound connections to reach the endpoints defined by a backend. An Ingress can be configured to give services externally-reachable urls, load balance traffic, terminate SSL, offer name based virtual hosting etc.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.Ingress" "ingresses" "Ingress" "networking.k8s.io" "v1"));
        default = { };
      };
      "ingressClasses" = mkOption {
        description = "IngressClass represents the class of the Ingress, referenced by the Ingress Spec. The `ingressclass.kubernetes.io/is-default-class` annotation can be used to indicate that an IngressClass should be considered default. When a single IngressClass resource has this annotation set to true, new Ingress resources without a class specified will be assigned this default class.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.IngressClass" "ingressclasses" "IngressClass" "networking.k8s.io" "v1"));
        default = { };
      };
      "jobs" = mkOption {
        description = "Job represents the configuration of a single job.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.batch.v1.Job" "jobs" "Job" "batch" "v1"));
        default = { };
      };
      "leases" = mkOption {
        description = "Lease defines a lease concept.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.coordination.v1.Lease" "leases" "Lease" "coordination.k8s.io" "v1"));
        default = { };
      };
      "limitRanges" = mkOption {
        description = "LimitRange sets resource usage limits for each kind of resource in a Namespace.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.LimitRange" "limitranges" "LimitRange" "core" "v1"));
        default = { };
      };
      "localSubjectAccessReviews" = mkOption {
        description = "LocalSubjectAccessReview checks whether or not a user or group can perform an action in a given namespace. Having a namespace scoped resource makes it much easier to grant namespace scoped policy that includes permissions checking.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.LocalSubjectAccessReview" "localsubjectaccessreviews" "LocalSubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "mutatingWebhookConfigurations" = mkOption {
        description = "MutatingWebhookConfiguration describes the configuration of and admission webhook that accept or reject and may change the object.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1.MutatingWebhookConfiguration" "mutatingwebhookconfigurations" "MutatingWebhookConfiguration" "admissionregistration.k8s.io" "v1"));
        default = { };
      };
      "namespaces" = mkOption {
        description = "Namespace provides a scope for Names. Use of multiple namespaces is optional.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Namespace" "namespaces" "Namespace" "core" "v1"));
        default = { };
      };
      "networkPolicies" = mkOption {
        description = "NetworkPolicy describes what network traffic is allowed for a set of Pods";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.networking.v1.NetworkPolicy" "networkpolicies" "NetworkPolicy" "networking.k8s.io" "v1"));
        default = { };
      };
      "nodes" = mkOption {
        description = "Node is a worker node in Kubernetes. Each node will have a unique identifier in the cache (i.e. in etcd).";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Node" "nodes" "Node" "core" "v1"));
        default = { };
      };
      "persistentVolumes" = mkOption {
        description = "PersistentVolume (PV) is a storage resource provisioned by an administrator. It is analogous to a node. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PersistentVolume" "persistentvolumes" "PersistentVolume" "core" "v1"));
        default = { };
      };
      "persistentVolumeClaims" = mkOption {
        description = "PersistentVolumeClaim is a user's request for and claim to a persistent volume";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PersistentVolumeClaim" "persistentvolumeclaims" "PersistentVolumeClaim" "core" "v1"));
        default = { };
      };
      "pods" = mkOption {
        description = "Pod is a collection of containers that can run on a host. This resource is created by clients and scheduled onto hosts.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Pod" "pods" "Pod" "core" "v1"));
        default = { };
      };
      "podDisruptionBudgets" = mkOption {
        description = "PodDisruptionBudget is an object to define the max disruption that can be caused to a collection of pods";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.policy.v1.PodDisruptionBudget" "poddisruptionbudgets" "PodDisruptionBudget" "policy" "v1"));
        default = { };
      };
      "podSchedulings" = mkOption {
        description = "PodScheduling objects hold information that is needed to schedule a Pod with ResourceClaims that use \"WaitForFirstConsumer\" allocation mode.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.PodScheduling" "podschedulings" "PodScheduling" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "podTemplates" = mkOption {
        description = "PodTemplate describes a template for creating copies of a predefined pod.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.PodTemplate" "podtemplates" "PodTemplate" "core" "v1"));
        default = { };
      };
      "priorityClasses" = mkOption {
        description = "PriorityClass defines mapping from a priority class name to the priority integer value. The value can be any valid integer.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.scheduling.v1.PriorityClass" "priorityclasses" "PriorityClass" "scheduling.k8s.io" "v1"));
        default = { };
      };
      "priorityLevelConfigurations" = mkOption {
        description = "PriorityLevelConfiguration represents the configuration of a priority level.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.flowcontrol.v1beta3.PriorityLevelConfiguration" "prioritylevelconfigurations" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io" "v1beta3"));
        default = { };
      };
      "replicaSets" = mkOption {
        description = "ReplicaSet ensures that a specified number of pod replicas are running at any given time.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.ReplicaSet" "replicasets" "ReplicaSet" "apps" "v1"));
        default = { };
      };
      "replicationControllers" = mkOption {
        description = "ReplicationController represents the configuration of a replication controller.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ReplicationController" "replicationcontrollers" "ReplicationController" "core" "v1"));
        default = { };
      };
      "resourceClaims" = mkOption {
        description = "ResourceClaim describes which resources are needed by a resource consumer. Its status tracks whether the resource has been allocated and what the resulting attributes are.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClaim" "resourceclaims" "ResourceClaim" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resourceClaimTemplates" = mkOption {
        description = "ResourceClaimTemplate is used to produce ResourceClaim objects.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClaimTemplate" "resourceclaimtemplates" "ResourceClaimTemplate" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resourceClasses" = mkOption {
        description = "ResourceClass is used by administrators to influence how resources are allocated.\n\nThis is an alpha type and requires enabling the DynamicResourceAllocation feature gate.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.resource.v1alpha1.ResourceClass" "resourceclasses" "ResourceClass" "resource.k8s.io" "v1alpha1"));
        default = { };
      };
      "resourceQuotas" = mkOption {
        description = "ResourceQuota sets aggregate quota restrictions enforced per namespace";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ResourceQuota" "resourcequotas" "ResourceQuota" "core" "v1"));
        default = { };
      };
      "roles" = mkOption {
        description = "Role is a namespaced, logical grouping of PolicyRules that can be referenced as a unit by a RoleBinding.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.Role" "roles" "Role" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "roleBindings" = mkOption {
        description = "RoleBinding references a role, but does not contain it.  It can reference a Role in the same namespace or a ClusterRole in the global namespace. It adds who information via Subjects and namespace information by which namespace it exists in.  RoleBindings in a given namespace only have effect in that namespace.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.rbac.v1.RoleBinding" "rolebindings" "RoleBinding" "rbac.authorization.k8s.io" "v1"));
        default = { };
      };
      "runtimeClasses" = mkOption {
        description = "RuntimeClass defines a class of container runtime supported in the cluster. The RuntimeClass is used to determine which container runtime is used to run all containers in a pod. RuntimeClasses are manually defined by a user or cluster provisioner, and referenced in the PodSpec. The Kubelet is responsible for resolving the RuntimeClassName reference before running the pod.  For more details, see https://kubernetes.io/docs/concepts/containers/runtime-class/";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.node.v1.RuntimeClass" "runtimeclasses" "RuntimeClass" "node.k8s.io" "v1"));
        default = { };
      };
      "secrets" = mkOption {
        description = "Secret holds secret data of a certain type. The total bytes of the values in the Data field must be less than MaxSecretSize bytes.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Secret" "secrets" "Secret" "core" "v1"));
        default = { };
      };
      "selfSubjectAccessReviews" = mkOption {
        description = "SelfSubjectAccessReview checks whether or the current user can perform an action.  Not filling in a spec.namespace means \"in all namespaces\".  Self is a special case, because users should always be able to check whether they can perform an action";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SelfSubjectAccessReview" "selfsubjectaccessreviews" "SelfSubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "selfSubjectReviews" = mkOption {
        description = "SelfSubjectReview contains the user information that the kube-apiserver has about the user making this request. When using impersonation, users will receive the user info of the user being impersonated.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1alpha1.SelfSubjectReview" "selfsubjectreviews" "SelfSubjectReview" "authentication.k8s.io" "v1alpha1"));
        default = { };
      };
      "selfSubjectRulesReviews" = mkOption {
        description = "SelfSubjectRulesReview enumerates the set of actions the current user can perform within a namespace. The returned list of actions may be incomplete depending on the server's authorization mode, and any errors experienced during the evaluation. SelfSubjectRulesReview should be used by UIs to show/hide actions, or to quickly let an end user reason about their permissions. It should NOT Be used by external systems to drive authorization decisions as this raises confused deputy, cache lifetime/revocation, and correctness concerns. SubjectAccessReview, and LocalAccessReview are the correct way to defer authorization decisions to the API server.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SelfSubjectRulesReview" "selfsubjectrulesreviews" "SelfSubjectRulesReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "services" = mkOption {
        description = "Service is a named abstraction of software service (for example, mysql) consisting of local port (for example 3306) that the proxy listens on, and the selector that determines which pods will answer requests sent through the proxy.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.Service" "services" "Service" "core" "v1"));
        default = { };
      };
      "serviceAccounts" = mkOption {
        description = "ServiceAccount binds together: * a name, understood by users, and perhaps by peripheral systems, for an identity * a principal that can be authenticated and authorized * a set of secrets";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.core.v1.ServiceAccount" "serviceaccounts" "ServiceAccount" "core" "v1"));
        default = { };
      };
      "statefulSets" = mkOption {
        description = "StatefulSet represents a set of pods with consistent identities. Identities are defined as:\n  - Network: A single stable DNS and hostname.\n  - Storage: As many VolumeClaims as requested.\n\nThe StatefulSet guarantees that a given network identity will always map to the same storage identity.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apps.v1.StatefulSet" "statefulsets" "StatefulSet" "apps" "v1"));
        default = { };
      };
      "storageClasses" = mkOption {
        description = "StorageClass describes the parameters for a class of storage for which PersistentVolumes can be dynamically provisioned.\n\nStorageClasses are non-namespaced; the name of the storage class according to etcd is in ObjectMeta.Name.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.StorageClass" "storageclasses" "StorageClass" "storage.k8s.io" "v1"));
        default = { };
      };
      "storageVersions" = mkOption {
        description = "Storage version of a specific resource.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.apiserverinternal.v1alpha1.StorageVersion" "storageversions" "StorageVersion" "internal.apiserver.k8s.io" "v1alpha1"));
        default = { };
      };
      "subjectAccessReviews" = mkOption {
        description = "SubjectAccessReview checks whether or not a user or group can perform an action.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authorization.v1.SubjectAccessReview" "subjectaccessreviews" "SubjectAccessReview" "authorization.k8s.io" "v1"));
        default = { };
      };
      "token" = mkOption {
        description = "TokenRequest requests a token for a given service account.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1.TokenRequest" "token" "TokenRequest" "authentication.k8s.io" "v1"));
        default = { };
      };
      "tokenReviews" = mkOption {
        description = "TokenReview attempts to authenticate a token to a known user. Note: TokenReview requests may be cached by the webhook token authenticator plugin in the kube-apiserver.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.authentication.v1.TokenReview" "tokenreviews" "TokenReview" "authentication.k8s.io" "v1"));
        default = { };
      };
      "validatingAdmissionPolicies" = mkOption {
        description = "ValidatingAdmissionPolicy describes the definition of an admission validation policy that accepts or rejects an object without changing it.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicy" "validatingadmissionpolicies" "ValidatingAdmissionPolicy" "admissionregistration.k8s.io" "v1alpha1"));
        default = { };
      };
      "validatingAdmissionPolicyBindings" = mkOption {
        description = "ValidatingAdmissionPolicyBinding binds the ValidatingAdmissionPolicy with paramerized resources. ValidatingAdmissionPolicyBinding and parameter CRDs together define how cluster administrators configure policies for clusters.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1alpha1.ValidatingAdmissionPolicyBinding" "validatingadmissionpolicybindings" "ValidatingAdmissionPolicyBinding" "admissionregistration.k8s.io" "v1alpha1"));
        default = { };
      };
      "validatingWebhookConfigurations" = mkOption {
        description = "ValidatingWebhookConfiguration describes the configuration of and admission webhook that accept or reject and object without changing it.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.admissionregistration.v1.ValidatingWebhookConfiguration" "validatingwebhookconfigurations" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io" "v1"));
        default = { };
      };
      "volumeAttachments" = mkOption {
        description = "VolumeAttachment captures the intent to attach or detach the specified volume to/from the specified node.\n\nVolumeAttachment objects are non-namespaced.";
        type = (types.attrsOf (submoduleForDefinition "io.k8s.api.storage.v1.VolumeAttachment" "volumeattachments" "VolumeAttachment" "storage.k8s.io" "v1"));
        default = { };
      };

    };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [{
      name = "mutatingwebhookconfigurations";
      group = "admissionregistration.k8s.io";
      version = "v1";
      kind = "MutatingWebhookConfiguration";
      attrName = "mutatingWebhookConfigurations";
    }
      {
        name = "validatingwebhookconfigurations";
        group = "admissionregistration.k8s.io";
        version = "v1";
        kind = "ValidatingWebhookConfiguration";
        attrName = "validatingWebhookConfigurations";
      }
      {
        name = "validatingadmissionpolicies";
        group = "admissionregistration.k8s.io";
        version = "v1alpha1";
        kind = "ValidatingAdmissionPolicy";
        attrName = "validatingAdmissionPolicies";
      }
      {
        name = "validatingadmissionpolicybindings";
        group = "admissionregistration.k8s.io";
        version = "v1alpha1";
        kind = "ValidatingAdmissionPolicyBinding";
        attrName = "validatingAdmissionPolicyBindings";
      }
      {
        name = "storageversions";
        group = "internal.apiserver.k8s.io";
        version = "v1alpha1";
        kind = "StorageVersion";
        attrName = "storageVersions";
      }
      {
        name = "controllerrevisions";
        group = "apps";
        version = "v1";
        kind = "ControllerRevision";
        attrName = "controllerRevisions";
      }
      {
        name = "daemonsets";
        group = "apps";
        version = "v1";
        kind = "DaemonSet";
        attrName = "daemonSets";
      }
      {
        name = "deployments";
        group = "apps";
        version = "v1";
        kind = "Deployment";
        attrName = "deployments";
      }
      {
        name = "replicasets";
        group = "apps";
        version = "v1";
        kind = "ReplicaSet";
        attrName = "replicaSets";
      }
      {
        name = "statefulsets";
        group = "apps";
        version = "v1";
        kind = "StatefulSet";
        attrName = "statefulSets";
      }
      {
        name = "token";
        group = "authentication.k8s.io";
        version = "v1";
        kind = "TokenRequest";
        attrName = "token";
      }
      {
        name = "tokenreviews";
        group = "authentication.k8s.io";
        version = "v1";
        kind = "TokenReview";
        attrName = "tokenReviews";
      }
      {
        name = "selfsubjectreviews";
        group = "authentication.k8s.io";
        version = "v1alpha1";
        kind = "SelfSubjectReview";
        attrName = "selfSubjectReviews";
      }
      {
        name = "localsubjectaccessreviews";
        group = "authorization.k8s.io";
        version = "v1";
        kind = "LocalSubjectAccessReview";
        attrName = "localSubjectAccessReviews";
      }
      {
        name = "selfsubjectaccessreviews";
        group = "authorization.k8s.io";
        version = "v1";
        kind = "SelfSubjectAccessReview";
        attrName = "selfSubjectAccessReviews";
      }
      {
        name = "selfsubjectrulesreviews";
        group = "authorization.k8s.io";
        version = "v1";
        kind = "SelfSubjectRulesReview";
        attrName = "selfSubjectRulesReviews";
      }
      {
        name = "subjectaccessreviews";
        group = "authorization.k8s.io";
        version = "v1";
        kind = "SubjectAccessReview";
        attrName = "subjectAccessReviews";
      }
      {
        name = "horizontalpodautoscalers";
        group = "autoscaling";
        version = "v1";
        kind = "HorizontalPodAutoscaler";
        attrName = "horizontalPodAutoscalers";
      }
      {
        name = "horizontalpodautoscalers";
        group = "autoscaling";
        version = "v2";
        kind = "HorizontalPodAutoscaler";
        attrName = "horizontalPodAutoscalers";
      }
      {
        name = "cronjobs";
        group = "batch";
        version = "v1";
        kind = "CronJob";
        attrName = "cronJobs";
      }
      {
        name = "jobs";
        group = "batch";
        version = "v1";
        kind = "Job";
        attrName = "jobs";
      }
      {
        name = "certificatesigningrequests";
        group = "certificates.k8s.io";
        version = "v1";
        kind = "CertificateSigningRequest";
        attrName = "certificateSigningRequests";
      }
      {
        name = "leases";
        group = "coordination.k8s.io";
        version = "v1";
        kind = "Lease";
        attrName = "leases";
      }
      {
        name = "bindings";
        group = "core";
        version = "v1";
        kind = "Binding";
        attrName = "bindings";
      }
      {
        name = "configmaps";
        group = "core";
        version = "v1";
        kind = "ConfigMap";
        attrName = "configMaps";
      }
      {
        name = "endpoints";
        group = "core";
        version = "v1";
        kind = "Endpoints";
        attrName = "endpoints";
      }
      {
        name = "events";
        group = "core";
        version = "v1";
        kind = "Event";
        attrName = "events";
      }
      {
        name = "limitranges";
        group = "core";
        version = "v1";
        kind = "LimitRange";
        attrName = "limitRanges";
      }
      {
        name = "namespaces";
        group = "core";
        version = "v1";
        kind = "Namespace";
        attrName = "namespaces";
      }
      {
        name = "nodes";
        group = "core";
        version = "v1";
        kind = "Node";
        attrName = "nodes";
      }
      {
        name = "persistentvolumes";
        group = "core";
        version = "v1";
        kind = "PersistentVolume";
        attrName = "persistentVolumes";
      }
      {
        name = "persistentvolumeclaims";
        group = "core";
        version = "v1";
        kind = "PersistentVolumeClaim";
        attrName = "persistentVolumeClaims";
      }
      {
        name = "pods";
        group = "core";
        version = "v1";
        kind = "Pod";
        attrName = "pods";
      }
      {
        name = "podtemplates";
        group = "core";
        version = "v1";
        kind = "PodTemplate";
        attrName = "podTemplates";
      }
      {
        name = "replicationcontrollers";
        group = "core";
        version = "v1";
        kind = "ReplicationController";
        attrName = "replicationControllers";
      }
      {
        name = "resourcequotas";
        group = "core";
        version = "v1";
        kind = "ResourceQuota";
        attrName = "resourceQuotas";
      }
      {
        name = "secrets";
        group = "core";
        version = "v1";
        kind = "Secret";
        attrName = "secrets";
      }
      {
        name = "services";
        group = "core";
        version = "v1";
        kind = "Service";
        attrName = "services";
      }
      {
        name = "serviceaccounts";
        group = "core";
        version = "v1";
        kind = "ServiceAccount";
        attrName = "serviceAccounts";
      }
      {
        name = "endpointslices";
        group = "discovery.k8s.io";
        version = "v1";
        kind = "EndpointSlice";
        attrName = "endpointSlices";
      }
      {
        name = "events";
        group = "events.k8s.io";
        version = "v1";
        kind = "Event";
        attrName = "events";
      }
      {
        name = "flowschemas";
        group = "flowcontrol.apiserver.k8s.io";
        version = "v1beta2";
        kind = "FlowSchema";
        attrName = "flowSchemas";
      }
      {
        name = "prioritylevelconfigurations";
        group = "flowcontrol.apiserver.k8s.io";
        version = "v1beta2";
        kind = "PriorityLevelConfiguration";
        attrName = "priorityLevelConfigurations";
      }
      {
        name = "flowschemas";
        group = "flowcontrol.apiserver.k8s.io";
        version = "v1beta3";
        kind = "FlowSchema";
        attrName = "flowSchemas";
      }
      {
        name = "prioritylevelconfigurations";
        group = "flowcontrol.apiserver.k8s.io";
        version = "v1beta3";
        kind = "PriorityLevelConfiguration";
        attrName = "priorityLevelConfigurations";
      }
      {
        name = "ingresses";
        group = "networking.k8s.io";
        version = "v1";
        kind = "Ingress";
        attrName = "ingresses";
      }
      {
        name = "ingressclasses";
        group = "networking.k8s.io";
        version = "v1";
        kind = "IngressClass";
        attrName = "ingressClasses";
      }
      {
        name = "networkpolicies";
        group = "networking.k8s.io";
        version = "v1";
        kind = "NetworkPolicy";
        attrName = "networkPolicies";
      }
      {
        name = "clustercidrs";
        group = "networking.k8s.io";
        version = "v1alpha1";
        kind = "ClusterCIDR";
        attrName = "clusterCIDRs";
      }
      {
        name = "runtimeclasses";
        group = "node.k8s.io";
        version = "v1";
        kind = "RuntimeClass";
        attrName = "runtimeClasses";
      }
      {
        name = "eviction";
        group = "policy";
        version = "v1";
        kind = "Eviction";
        attrName = "eviction";
      }
      {
        name = "poddisruptionbudgets";
        group = "policy";
        version = "v1";
        kind = "PodDisruptionBudget";
        attrName = "podDisruptionBudgets";
      }
      {
        name = "clusterroles";
        group = "rbac.authorization.k8s.io";
        version = "v1";
        kind = "ClusterRole";
        attrName = "clusterRoles";
      }
      {
        name = "clusterrolebindings";
        group = "rbac.authorization.k8s.io";
        version = "v1";
        kind = "ClusterRoleBinding";
        attrName = "clusterRoleBindings";
      }
      {
        name = "roles";
        group = "rbac.authorization.k8s.io";
        version = "v1";
        kind = "Role";
        attrName = "roles";
      }
      {
        name = "rolebindings";
        group = "rbac.authorization.k8s.io";
        version = "v1";
        kind = "RoleBinding";
        attrName = "roleBindings";
      }
      {
        name = "podschedulings";
        group = "resource.k8s.io";
        version = "v1alpha1";
        kind = "PodScheduling";
        attrName = "podSchedulings";
      }
      {
        name = "resourceclaims";
        group = "resource.k8s.io";
        version = "v1alpha1";
        kind = "ResourceClaim";
        attrName = "resourceClaims";
      }
      {
        name = "resourceclaimtemplates";
        group = "resource.k8s.io";
        version = "v1alpha1";
        kind = "ResourceClaimTemplate";
        attrName = "resourceClaimTemplates";
      }
      {
        name = "resourceclasses";
        group = "resource.k8s.io";
        version = "v1alpha1";
        kind = "ResourceClass";
        attrName = "resourceClasses";
      }
      {
        name = "priorityclasses";
        group = "scheduling.k8s.io";
        version = "v1";
        kind = "PriorityClass";
        attrName = "priorityClasses";
      }
      {
        name = "csidrivers";
        group = "storage.k8s.io";
        version = "v1";
        kind = "CSIDriver";
        attrName = "cSIDrivers";
      }
      {
        name = "csinodes";
        group = "storage.k8s.io";
        version = "v1";
        kind = "CSINode";
        attrName = "cSINodes";
      }
      {
        name = "csistoragecapacities";
        group = "storage.k8s.io";
        version = "v1";
        kind = "CSIStorageCapacity";
        attrName = "cSIStorageCapacities";
      }
      {
        name = "storageclasses";
        group = "storage.k8s.io";
        version = "v1";
        kind = "StorageClass";
        attrName = "storageClasses";
      }
      {
        name = "volumeattachments";
        group = "storage.k8s.io";
        version = "v1";
        kind = "VolumeAttachment";
        attrName = "volumeAttachments";
      }
      {
        name = "csistoragecapacities";
        group = "storage.k8s.io";
        version = "v1beta1";
        kind = "CSIStorageCapacity";
        attrName = "cSIStorageCapacities";
      }
      {
        name = "customresourcedefinitions";
        group = "apiextensions.k8s.io";
        version = "v1";
        kind = "CustomResourceDefinition";
        attrName = "customResourceDefinitions";
      }
      {
        name = "apiservices";
        group = "apiregistration.k8s.io";
        version = "v1";
        kind = "APIService";
        attrName = "APIServices";
      }];

    resources = {
      "apiregistration.k8s.io"."v1"."APIService" =
        mkAliasDefinitions options.resources."APIServices";
      "core"."v1"."Binding" =
        mkAliasDefinitions options.resources."bindings";
      "storage.k8s.io"."v1"."CSIDriver" =
        mkAliasDefinitions options.resources."cSIDrivers";
      "storage.k8s.io"."v1"."CSINode" =
        mkAliasDefinitions options.resources."cSINodes";
      "storage.k8s.io"."v1"."CSIStorageCapacity" =
        mkAliasDefinitions options.resources."cSIStorageCapacities";
      "certificates.k8s.io"."v1"."CertificateSigningRequest" =
        mkAliasDefinitions options.resources."certificateSigningRequests";
      "networking.k8s.io"."v1alpha1"."ClusterCIDR" =
        mkAliasDefinitions options.resources."clusterCIDRs";
      "rbac.authorization.k8s.io"."v1"."ClusterRole" =
        mkAliasDefinitions options.resources."clusterRoles";
      "rbac.authorization.k8s.io"."v1"."ClusterRoleBinding" =
        mkAliasDefinitions options.resources."clusterRoleBindings";
      "core"."v1"."ConfigMap" =
        mkAliasDefinitions options.resources."configMaps";
      "apps"."v1"."ControllerRevision" =
        mkAliasDefinitions options.resources."controllerRevisions";
      "batch"."v1"."CronJob" =
        mkAliasDefinitions options.resources."cronJobs";
      "apiextensions.k8s.io"."v1"."CustomResourceDefinition" =
        mkAliasDefinitions options.resources."customResourceDefinitions";
      "apps"."v1"."DaemonSet" =
        mkAliasDefinitions options.resources."daemonSets";
      "apps"."v1"."Deployment" =
        mkAliasDefinitions options.resources."deployments";
      "discovery.k8s.io"."v1"."EndpointSlice" =
        mkAliasDefinitions options.resources."endpointSlices";
      "core"."v1"."Endpoints" =
        mkAliasDefinitions options.resources."endpoints";
      "core"."v1"."Event" =
        mkAliasDefinitions options.resources."events";
      "policy"."v1"."Eviction" =
        mkAliasDefinitions options.resources."eviction";
      "flowcontrol.apiserver.k8s.io"."v1beta3"."FlowSchema" =
        mkAliasDefinitions options.resources."flowSchemas";
      "autoscaling"."v2"."HorizontalPodAutoscaler" =
        mkAliasDefinitions options.resources."horizontalPodAutoscalers";
      "networking.k8s.io"."v1"."Ingress" =
        mkAliasDefinitions options.resources."ingresses";
      "networking.k8s.io"."v1"."IngressClass" =
        mkAliasDefinitions options.resources."ingressClasses";
      "batch"."v1"."Job" =
        mkAliasDefinitions options.resources."jobs";
      "coordination.k8s.io"."v1"."Lease" =
        mkAliasDefinitions options.resources."leases";
      "core"."v1"."LimitRange" =
        mkAliasDefinitions options.resources."limitRanges";
      "authorization.k8s.io"."v1"."LocalSubjectAccessReview" =
        mkAliasDefinitions options.resources."localSubjectAccessReviews";
      "admissionregistration.k8s.io"."v1"."MutatingWebhookConfiguration" =
        mkAliasDefinitions options.resources."mutatingWebhookConfigurations";
      "core"."v1"."Namespace" =
        mkAliasDefinitions options.resources."namespaces";
      "networking.k8s.io"."v1"."NetworkPolicy" =
        mkAliasDefinitions options.resources."networkPolicies";
      "core"."v1"."Node" =
        mkAliasDefinitions options.resources."nodes";
      "core"."v1"."PersistentVolume" =
        mkAliasDefinitions options.resources."persistentVolumes";
      "core"."v1"."PersistentVolumeClaim" =
        mkAliasDefinitions options.resources."persistentVolumeClaims";
      "core"."v1"."Pod" =
        mkAliasDefinitions options.resources."pods";
      "policy"."v1"."PodDisruptionBudget" =
        mkAliasDefinitions options.resources."podDisruptionBudgets";
      "resource.k8s.io"."v1alpha1"."PodScheduling" =
        mkAliasDefinitions options.resources."podSchedulings";
      "core"."v1"."PodTemplate" =
        mkAliasDefinitions options.resources."podTemplates";
      "scheduling.k8s.io"."v1"."PriorityClass" =
        mkAliasDefinitions options.resources."priorityClasses";
      "flowcontrol.apiserver.k8s.io"."v1beta3"."PriorityLevelConfiguration" =
        mkAliasDefinitions options.resources."priorityLevelConfigurations";
      "apps"."v1"."ReplicaSet" =
        mkAliasDefinitions options.resources."replicaSets";
      "core"."v1"."ReplicationController" =
        mkAliasDefinitions options.resources."replicationControllers";
      "resource.k8s.io"."v1alpha1"."ResourceClaim" =
        mkAliasDefinitions options.resources."resourceClaims";
      "resource.k8s.io"."v1alpha1"."ResourceClaimTemplate" =
        mkAliasDefinitions options.resources."resourceClaimTemplates";
      "resource.k8s.io"."v1alpha1"."ResourceClass" =
        mkAliasDefinitions options.resources."resourceClasses";
      "core"."v1"."ResourceQuota" =
        mkAliasDefinitions options.resources."resourceQuotas";
      "rbac.authorization.k8s.io"."v1"."Role" =
        mkAliasDefinitions options.resources."roles";
      "rbac.authorization.k8s.io"."v1"."RoleBinding" =
        mkAliasDefinitions options.resources."roleBindings";
      "node.k8s.io"."v1"."RuntimeClass" =
        mkAliasDefinitions options.resources."runtimeClasses";
      "core"."v1"."Secret" =
        mkAliasDefinitions options.resources."secrets";
      "authorization.k8s.io"."v1"."SelfSubjectAccessReview" =
        mkAliasDefinitions options.resources."selfSubjectAccessReviews";
      "authentication.k8s.io"."v1alpha1"."SelfSubjectReview" =
        mkAliasDefinitions options.resources."selfSubjectReviews";
      "authorization.k8s.io"."v1"."SelfSubjectRulesReview" =
        mkAliasDefinitions options.resources."selfSubjectRulesReviews";
      "core"."v1"."Service" =
        mkAliasDefinitions options.resources."services";
      "core"."v1"."ServiceAccount" =
        mkAliasDefinitions options.resources."serviceAccounts";
      "apps"."v1"."StatefulSet" =
        mkAliasDefinitions options.resources."statefulSets";
      "storage.k8s.io"."v1"."StorageClass" =
        mkAliasDefinitions options.resources."storageClasses";
      "internal.apiserver.k8s.io"."v1alpha1"."StorageVersion" =
        mkAliasDefinitions options.resources."storageVersions";
      "authorization.k8s.io"."v1"."SubjectAccessReview" =
        mkAliasDefinitions options.resources."subjectAccessReviews";
      "authentication.k8s.io"."v1"."TokenRequest" =
        mkAliasDefinitions options.resources."token";
      "authentication.k8s.io"."v1"."TokenReview" =
        mkAliasDefinitions options.resources."tokenReviews";
      "admissionregistration.k8s.io"."v1alpha1"."ValidatingAdmissionPolicy" =
        mkAliasDefinitions options.resources."validatingAdmissionPolicies";
      "admissionregistration.k8s.io"."v1alpha1"."ValidatingAdmissionPolicyBinding" =
        mkAliasDefinitions options.resources."validatingAdmissionPolicyBindings";
      "admissionregistration.k8s.io"."v1"."ValidatingWebhookConfiguration" =
        mkAliasDefinitions options.resources."validatingWebhookConfigurations";
      "storage.k8s.io"."v1"."VolumeAttachment" =
        mkAliasDefinitions options.resources."volumeAttachments";

    };
  };
}

