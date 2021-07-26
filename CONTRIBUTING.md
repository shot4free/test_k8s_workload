## Developer Certificate of Origin + License

By contributing to GitLab B.V., You accept and agree to the following terms and
conditions for Your present and future Contributions submitted to GitLab B.V.
Except for the license granted herein to GitLab B.V. and recipients of software
distributed by GitLab B.V., You reserve all right, title, and interest in and to
Your Contributions. All Contributions are subject to the following DCO + License
terms.

[DCO + License](https://gitlab.com/gitlab-org/dco/blob/master/README.md)

All Documentation content that resides under the [doc/ directory](/doc) of this
repository is licensed under Creative Commons:
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

_This notice should stay as the first item in the CONTRIBUTING.md file._

## Contributing guidelines

The instructions below assume that you have access to [the repository at its canonical location](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com). The canonical repository does not run production workloads, as the changes are mirrored to a separate instance that connects to production workloads.

The most common case for contributing to this project is to change configuration values to one of [the services](README.md#services), and the guide below makes this assumption. These services are deployed using the [official GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab). Ensure that the GitLab Chart supports the configuration prior to opening a MR.

### Merge requests contributors workflow

The workflow to make a merge request is as follows:

1. Clone the project and create a feature branch.
1. Make the necessary changes for [the right environment](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com#gitlab-environments-configuration). It is recommended that you create one MR per environment and link together.

  * Common configuration for all environments goes into [values.yaml.gotmpl](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl)
  * Environment specific configuration goes into one of the files in [values directory](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master/releases/gitlab/values). For example, production environment marked as `gprd` has a configuration file named [gprd.yaml.gotmpl](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl).
1. Commit and submit the MR with the changes.
1. MR description has to contain links to relevant resources, **and** explain why the specific change is being made.
1. For production web fleet changes - [Create a Criticality 4 change request issue](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#change-request-workflows) and link to the MR description. The change request is used for auditing purposes, if you are applying changes to Staging followed by Production, it is recommended you open a single change request for both environments.
1. Add link(s) to any related Chef changes. 
1. Apply the `Contribution` label, as well as any other applicable labels (Stage group labels, Service labels and similar).
1. Check the [Reviewer and Maintainer section](https://about.gitlab.com/handbook/engineering/projects/#k8s-workloads-gitlab-com) and assign to a reviewer and maintainer.
1. If the request is a part of corrective action for an active incident, assign the MR to the `SRE on-call`. Current on-call can be found in the [production channel](https://gitlab.slack.com/archives/C101F3796), in the `sre-oncall` user group.

### Merge request reviewers workflow

As a reviewer, you need to ensure a certain level of quality for the MR that is assigned for a review.
Keep the following flow in mind:

1. In order to make matters simpler, assume that the contributor has a limited perspective into how services run, so double check the intention of the MR.
1. Ensure that the MR description has context on why the change is made, and links to the applicable resources such as issues, epics, other related MRs as well as related Chef changes. Correct descriptions make it simpler to understand context by others not participating in the work, long after the MR is merged.
1. Ensure that MRs for production web fleet changes are linked to a corresponding change issue](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#change-request-workflows). 
1. Ensure that the MR has labels. Labels make it simpler to track multiple changes over time.
1. Review the CI pipeline comments from `ops-gitlab-net` user, as they contain the full pipeline run from the operational instance. The pipelines in the MR widget only run syntax checks.
1. Before merging the MR, ensure that the `Reviewer Check-list` section in the MR description is addressed.
1. Once the changes are reviewed, merge the MR and ensure that the changes are successfully applied to all applicable environments. Not doing so carries a risk of a failed rollout which does block regular operations such as deployments.
