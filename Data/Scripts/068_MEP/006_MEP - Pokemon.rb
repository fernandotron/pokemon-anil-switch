#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Pokemon
  def exp_fraction_for_panel(mock_exp)
    g_rate     = growth_rate
    mock_level = g_rate.level_from_exp(mock_exp)
    return [mock_level, 100.0] if mock_level >= GameData::GrowthRate.max_level
    start_exp = g_rate.minimum_exp_for_level(mock_level)
    end_exp   = g_rate.minimum_exp_for_level(mock_level + 1)
    range     = end_exp - start_exp
    return [mock_level, 0.0] if range <= 0
    ret       = (mock_exp - start_exp).to_f / range
    ret_pct   = [[ret, 0.0].max, 1.0].min * 100.0
    return [mock_level, ret_pct]
  end
end
