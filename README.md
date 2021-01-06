## AWS SSO Profile Tool

The AWS SSO Profile Tool is a script that helps create profiles for all the
accounts/roles you have access to as an AWS SSO user.  It can be thought of as
'aws configure sso' on steroids.

When you run the tool, you will be asked to log into AWS using in your browser,
after which the tool will walk through each account/role pair, giving you an
opportunity to create a profile if desired.  Once these profiles are created,
you can use them by specifying the profile name as an argument to the
'--profile' command line option.

### Installation

To install the tool, follow these steps:

1. Download the awsssoprofiletool.sh script onto your machine, using one of
the following methods:
* Clone the repository
* Download the ZIP file and unzip
* Copy and paste into a file
2. (Optional) Set the script as executable using _chmod +x
awsssoprofiletool.sh_ 

### Running

To run the script, do one of the following:

* If the script is executable, run it with _awsssoprofiletool.sh
<region> <start_url> [<profile_file>]_
* If the script is not executable, run it with  _bash awsssoprofiletool.sh
<region> <start_url> [<profile_file>]_

The arguments are as follows:

* <region> - the region where AWS SSO is running
* <start_url> - the start URL from the AWS SSO page
* <profile_file> - where the profiles will be created; defaults to ~/.aws/config

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

