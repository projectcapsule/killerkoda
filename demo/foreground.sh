echo "Installing scenario..."
while [ ! -f /tmp/finished ]; do
  if [ -f /tmp/failed ]; then
    echo "Scenario setup failed. See the Creator Debug output for details."
    exit 1
  fi
  sleep 2
done
echo "Ready to Play!"
