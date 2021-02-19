defmodule GlobalApi.Utils do
  alias GlobalApi.MojangApi
  alias GlobalApi.Repo

  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def get_env(key, atom) do
    Application.get_env(:global_api, key)[atom]
  end

  @doc """
  If the string is in range. Both min and max are inclusive
  """
  def is_in_range(string, min, max) do
    length = String.length(string)
    length >= min && length <= max
  end

  def hash_string(hash) do
    hash
    |> Base.encode16
    |> String.downcase
  end

  def is_int_and_rounded(xuid) do
    case String.contains?(xuid, ".") || String.starts_with?(xuid, "-") do
      true -> false
      false ->
        try do
          Decimal.integer?(xuid)
        rescue
          _ -> false
        end
    end
  end

  def update_username_if_needed_array(array) do
    update_username_if_needed_array(array, [])
  end

  defp update_username_if_needed_array([], []) do
    []
  end

  #todo make some changes here

  defp update_username_if_needed_array([current | remaining], []) do
    result = update_username_if_needed(current)
    if result[:lastNameUpdate] == DateTime.to_unix(current[:lastNameUpdate]),
       do: [result],
       else: update_username_if_needed_array(remaining, [result], result[:lastNameUpdate])
  end

  # if there are no more items to handle, return the result
  defp update_username_if_needed_array([], result, _) do
    result
  end

  defp update_username_if_needed_array([current | remaining], result, time) do
    data = %{current | lastUpdateTime: time}
    update_username_if_needed_array(remaining, [data | result], time)
  end

  def update_username_if_needed(%{javaId: javaId, javaName: javaName, lastNameUpdate: lastNameUpdate} = result) do
    timeSinceUpdate = DateTime.diff(DateTime.utc_now(), lastNameUpdate, :second)
    if timeSinceUpdate >= 86_400, # one day
       do: (
         username = MojangApi.get_current_username(javaId)
         if username != javaName,
            do: (
              updateTime = Repo.update_java_username(javaId, username)
              %{result | javaName: username, lastNameUpdate: DateTime.to_unix(updateTime)}
              ),
            else: (
              updateTime = Repo.update_last_name_update(javaId)
              %{result | lastNameUpdate: DateTime.to_unix(updateTime)}
              )
         ),
       else: %{result | lastNameUpdate: DateTime.to_unix(lastNameUpdate)}
  end

  # no link found
  def update_username_if_needed(result) do
    result
  end
end