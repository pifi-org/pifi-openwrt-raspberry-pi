

Using SSH, it’s possible to misconfigure your PiFi by manually adjusting settings.

Rather than forcing a factory reset / re-flash in that case and losing access to your configuration we have a few recovery options.

******Restore Config (Soft Reset)*******

If it’s a simple network misconfiguration (so anything you’d find in /etc/config) - then you can restore that by running 

sh /etc/restoreconfig

After this you can also restore your network settings in the PiFi app 

****

*******Full Factory Reset (SSH)******

If you prefer a full factory reset you can use

firstboot -y

******Full Factory Reset (Physical)******

You can also achieve this if you are using the PiFi adapter, simply by removing it and waiting 60 seconds.

****

In either case any files you have stored on the SD Card partition for file-sharing will be preserved.

For more help and tips, see pifi.org