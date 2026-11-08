import { test } from "node:test"
import assert from "node:assert/strict"
import { letterGrade, averageScore } from "../src/lib/grade.js"

test("letterGrade maps scores to letters", () => {
  assert.equal(letterGrade(92), "A")
  assert.equal(letterGrade(70), "B")
  assert.equal(letterGrade(60), "C")
  assert.equal(letterGrade(10), "D")
})

test("averageScore handles empty and filled lists", () => {
  assert.equal(averageScore([]), 0)
  assert.equal(averageScore([80, 90]), 85)
})
