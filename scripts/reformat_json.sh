find _data/early_access_trials -maxdepth 1 -type f \
    | xargs -I {} sh -c "python -m json.tool {} > /tmp/json; mv /tmp/json {}"
