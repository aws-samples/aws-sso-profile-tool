## AWS SSO Profile Tool

The AWS SSO Profile Tool is a script that helps create profiles for all the
accounts/roles you have access to as an AWS SSO user.  It can be thought of as
`aws configure sso` on steroids.

When you run the tool, you will be asked to log into AWS SSO using in your
browser, after which the tool will walk through each account/role pair, giving
you an opportunity to create a profile if desired.  Once these profiles are
created, you can use them by specifying the profile name as an argument to the
'--profile' command line option (e.g., `aws s3 ls --profile my_prfile`).

**Note:** You will always have to login to AWS SSO using the `aws sso login`
command before you can use any AWS SSO profile. However, once you have logged
in once, you will be able to use any of the created profiles until your
authorization token expires.

### Installation

To install the tool, follow these steps:

1. Download the awsssoprofiletool.sh script onto your machine, using one of
the following methods:
* Clone the repository
* Download the ZIP file and unzip
* Copy and paste the script into a file
2. (Optional) Make the awsssoprofiletool.sh script as executable using
`chmod +x awsssoprofiletool.sh`

### Running

To run the script, do one of the following:

* If the script is executable, run it with `./awsssoprofiletool.sh
<region> <start_url> [<profile_file>]`
* If the script is not executable, run it with  `bash awsssoprofiletool.sh
<region> <start_url> [<profile_file>]`

The arguments are as follows:

* &lt;region&gt; - the region where AWS SSO is running
* &lt;start_url&gt; - the start URL from the AWS SSO page
* &lt;profile_file&gt; - where the profiles will be created; defaults to
~/.aws/config

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

