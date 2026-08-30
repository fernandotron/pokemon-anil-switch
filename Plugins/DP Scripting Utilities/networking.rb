# Check if internet connection is available
# Cache for network connectivity status
# @network_check_cache = { status: nil, timestamp: 0 }
# CACHE_DURATION = 30 # seconds

# Check if internet connection is available
def network_available?
  # List of reliable endpoints to try
  endpoints = [
    "https://www.google.com",
    "https://1.1.1.1",     # Cloudflare DNS
    "https://8.8.8.8",     # Google DNS
    "https://api.github.com" # GitHub API as another option
  ]
  
  # Try each endpoint until one succeeds
  endpoints.each do |url|
    begin
      response = HTTPLite.get(url)
      if response && response.fetch(:status).between?(200, 399)
        return true
      end
    rescue MKXPError, NoMethodError, NameError
      # Continue to next endpoint
    rescue => e
      # Continue to next endpoint
    end
  end
  
  # If we get here, all endpoints failed
  return false
end