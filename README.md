# Auto-generate ModPagespeedLoadFromFile mappings

A Bash script to automate the generation of `ModPagespeedLoadFromFile` mappings for Apache's PageSpeed module. This script scans your web root and produces the necessary configuration lines, making it easier to serve static files efficiently with PageSpeed.

## Features  
- Automatically generates `ModPagespeedLoadFromFile` mappings for all files in a specified directory.  
- Simple setup and execution.  
- Works with any Apache server using the PageSpeed module.  

## Requirements  
- Bash shell  
- Access to the web root directory  
- Apache server with the PageSpeed module enabled  

## Installation  

1. Download the script using `wget`:  
   ```bash
   wget https://raw.githubusercontent.com/webdesires/Auto-generate-ModPagespeedLoadFromFile-mappings/main/updatemodpagespeedloadfromfile.sh
   ```  

2. Make the script executable:  
   ```bash
   chmod +x updatemodpagespeedloadfromfile.sh
   ```  

## Usage  

Run the script with:  
```bash
./updatemodpagespeedloadfromfile.sh
```  

Follow the prompts to provide the web root directory and the domain name.

## Disclaimer  

This script is provided "as-is," without any warranty. Use at your own risk. The authors are not responsible for any issues caused by using this script. Always back up your configuration before running any modification scripts.

## Donations  

If you find this script useful and would like to support its development, consider making a donation:

- PayPal: [Donate via PayPal](https://www.paypal.me/webdesires)  

Your contributions are greatly appreciated!

## License  

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.  
