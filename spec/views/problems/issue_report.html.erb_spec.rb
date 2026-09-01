# frozen_string_literal: true

require "rails_helper"

RSpec.describe "problems/issue_report.html.erb", type: :view do
  let(:app) { create(:app, github_repo: "errbit/errbit") }

  let(:problem) do
    problem = create(:problem, app: app)
    err = create(:err, problem: problem)
    create(:notice, err: err)
    ProblemDecorator.new(problem)
  end

  let(:issue) { Issue.new(problem: problem, user: create(:user)) }

  before do
    allow(view).to receive(:problem).and_return(problem)
    allow(view).to receive(:app).and_return(AppDecorator.new(app))

    assign :issue, issue
    assign :issue_body, "the issue body"
  end

  it "shows a readonly title field and body textarea" do
    render

    expect(rendered).to have_field("issue_title", with: issue.title, readonly: true)
    expect(rendered).to have_field("issue_body", with: "the issue body", readonly: true)
  end

  it "wires the fields to the clipboard controller rather than inline javascript" do
    render

    expect(rendered).to have_selector(
      "[data-clipboard-target='source'][data-action='click->clipboard#select']", count: 2
    )
    expect(rendered).not_to include("onclick")
  end

  it "offers a form to link a hand-filed issue back to the problem" do
    render

    expect(rendered).to have_selector(
      "form[action='#{link_issue_app_problem_path(app, problem)}'][method='post'] input[name='issue_link']"
    )
  end

  # A repo whose name contains "new" must not have it mangled.
  it "shows an example issue url of the repo as the placeholder" do
    app.update(github_repo: "errbit/new-errbit")

    render

    expect(rendered).to have_selector(
      "input[name='issue_link'][placeholder='https://github.com/errbit/new-errbit/issues/123']"
    )
  end

  it "prefills the link form with an already linked issue" do
    problem.update(issue_link: "https://github.com/errbit/errbit/issues/123")

    render

    expect(rendered).to have_field("issue_link", with: "https://github.com/errbit/errbit/issues/123")
  end

  it "links to the github issues pages" do
    render

    action_bar = view.content_for(:action_bar)

    expect(action_bar).to have_selector(
      "span.github a[href='#{app.github_new_issue_url(issue.title)}']",
      text: I18n.t("problems.issue_report.open_new_github_issue")
    )
    expect(action_bar).to have_selector(
      "span.github a[href='#{app.github_issues_url}']",
      text: I18n.t("problems.issue_report.browse_github_issues")
    )
  end

  context "without a github repo" do
    let(:app) { create(:app) }

    it "hides the github links" do
      render

      expect(view.content_for(:action_bar)).to have_no_selector("span.github")
    end

    it "leaves the link form without a placeholder" do
      render

      expect(rendered).to have_no_selector("input[name='issue_link'][placeholder]")
    end
  end
end
