SETUP_LOG=/tmp/scenario-setup.log
SETUP_ERROR=/tmp/scenario-setup-error.log

echo "Installing scenario..."
echo "Setup log: ${SETUP_LOG}"
while [ ! -f /tmp/finished ]; do
  if [ -f /tmp/failed ]; then
    echo
    if [ -s "${SETUP_ERROR}" ]; then
      cat "${SETUP_ERROR}"
    else
      echo "Scenario setup failed."
    fi
    if [ -s "${SETUP_LOG}" ]; then
      echo
      echo "Last 100 setup log lines:"
      tail -n 100 "${SETUP_LOG}"
    fi
    echo
    echo "Full setup log: ${SETUP_LOG}"
    exit 1
  fi
  sleep 2
done
echo "Ready to Play!"
