#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: USBIP Mounter
# Configures USBIP devices
# ==============================================================================

# Configure mount script for all usbip devices
declare server_address
declare bus_id
declare vendor_id
declare device_id
declare script_directory
declare mount_script

script_directory="/usr/local/bin"
mount_script="/usr/local/bin/mount_devices"

if ! bashio::fs.directory_exists "${script_directory}"; then
  bashio::log.info  "Creating script directory"
  mkdir -p "${script_directory}" || bashio::exit.nok "Could not create bin folder"
fi

if bashio::fs.file_exists "${mount_script}"; then
  rm "${mount_script}"
fi

if ! bashio::fs.file_exists "${mount_script}"; then
  touch ${mount_script}
  chmod +x ${mount_script}
  echo '#!/command/with-contenv bashio' > "${mount_script}"
  echo 'set -x' >> "${mount_script}"
  for device in $(bashio::config 'devices|keys'); do
    server_address=$(bashio::config "devices[${device}].server_address")
    bus_id=$(bashio::config "devices[${device}].bus_id")
    if [-z "${bus_id}"]; then
      vendor_id=$(bashio::config "devices[${device}].vendor_id")
      device_id=$(bashio::config "devices[${device}].device_id")
      bashio::log.info "Adding device from server ${server_address} with vendor id ${vendor_id} and device id ${device_id}"
      echo "/usr/sbin/usbip --debug attach -r ${server_address} --$(/usr/sbin/usbip list -p -r ${server_address} \| grep \'\#usbid=${vendor_id}\':\'${device_id}\'\# \| cut \'-d\#\' -f1)"
    else
      bashio::log.info "Adding device from server ${server_address} on bus ${bus_id}"
      echo "/usr/sbin/usbip --debug attach -r ${server_address} -b ${bus_id}" >> "${mount_script}"
    fi
  done
fi
