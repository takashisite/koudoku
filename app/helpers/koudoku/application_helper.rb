module Koudoku
  module ApplicationHelper

    def plan_price(plan)
      "#{number_to_currency(plan.price)}/#{plan_interval(plan)}"
    end

    def plan_interval(plan)
      case plan.interval
      when "3 days"
        "3days"
      when "month"
        "month"
      when "year"
        "year"
      when "week"
        "week"
      when "6-month"
        "half-year"
      when "3-month"
        "quarter"
      else
        "month"
      end
    end

  end
end
