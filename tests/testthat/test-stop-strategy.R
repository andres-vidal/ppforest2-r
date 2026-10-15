describe("stop_pure_node", {
  it("creates a stop_strategy object", {
    s <- stop_pure_node()
    expect_s3_class(s, "stop_strategy")
    expect_equal(s$name, "pure_node")
  })
})

describe("stop_min_size", {
  it("creates a stop_strategy object", {
    s <- stop_min_size(5L)
    expect_s3_class(s, "stop_strategy")
    expect_equal(s$name, "min_size")
    expect_equal(s$min_size, 5L)
  })

  it("rejects min_size < 2", {
    expect_error(stop_min_size(0L), ">= 2")
    expect_error(stop_min_size(1L), ">= 2")
  })

  it("rejects values that are not a single integer", {
    expect_error(stop_min_size(c(3, 4)), "single integer")
    expect_error(stop_min_size("a"), "single integer")
    expect_error(stop_min_size(NA), "single integer")
    expect_error(stop_min_size(2.5), "single integer")
  })
})

describe("stop_min_variance", {
  it("creates a stop_strategy object", {
    s <- stop_min_variance(0.01)
    expect_s3_class(s, "stop_strategy")
    expect_equal(s$name, "min_variance")
    expect_equal(s$threshold, 0.01)
  })

  it("rejects negative thresholds", {
    expect_error(stop_min_variance(-1), "non-negative")
  })
})

describe("stop_any", {
  it("combines rules", {
    s <- stop_any(stop_min_size(5L), stop_min_variance(0.01))
    expect_s3_class(s, "stop_strategy")
    expect_equal(s$name, "any")
    expect_length(s$rules, 2L)
  })

  it("rejects empty call", {
    expect_error(stop_any(), "at least one stop rule")
  })

  it("rejects non-stop_strategy arguments", {
    expect_error(stop_any("not a rule"), "stop_strategy")
  })
})

describe("stop rule argument checks", {
  it("stop_min_variance rejects values that are not a single non-negative number", {
    expect_error(stop_min_variance(c(0.1, 0.2)), "single non-negative number")
    expect_error(stop_min_variance(-1), "single non-negative number")
    expect_error(stop_min_variance(Inf), "single non-negative number")
  })

  it("stop_max_depth rejects values that are not a single non-negative integer", {
    expect_error(stop_max_depth(2.7), "single non-negative integer")
    expect_error(stop_max_depth(c(1, 2)), "single non-negative integer")
    expect_error(stop_max_depth(-1), "single non-negative integer")
  })
})
