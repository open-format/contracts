OPERATIONS_WALLET="0x10CE240074E46579E535506B38A2e6E852c49c8E"

if [ "${WALLET_ADDRESS}" = "${OPERATIONS_WALLET}" ]; then
  echo "Using operator wallet"
else
  echo -e "\nWARNING:\nYou are not using the operations wallet."
  read -p "Continue? (Y/n): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Continuing..."
  else
    echo "Script aborted."
    exit 1
  fi
fi
