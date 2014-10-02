require_relative '../integration_test_helper'

class EditingTagsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_user_with_permission('manage_tags')

    # stub the router + rummager requests so that artefact creation doesn't
    # fire off a bunch of web requests
    stub_all_router_api_requests
    stub_all_rummager_requests
  end

  context 'editing a live tag' do
    setup do
      @tag = create(:live_tag, tag_type: 'section',
                               tag_id: 'driving',
                               title: 'Driving',
                               description: 'Car tax, MOTs and driving licences')
    end

    should 'display the form' do
      visit edit_tag_path(@tag)

      within "header.artefact-header" do
        assert page.has_content?('Section: Driving')
        assert page.has_link?('/browse/driving', href: 'http://www.dev.gov.uk/browse/driving')
        assert page.has_selector?('.state-live', text: 'live')
      end

      within 'form.tag' do
        assert page.has_field?('Title', with: @tag.title)
        assert page.has_field?('Description', with: @tag.description)
        assert page.has_button?('Save this section')
      end

      assert page.has_selector?('.take-care')
    end

    should 'not display a publish button' do
      visit edit_tag_path(@tag)

      assert page.has_no_button?('Publish this section')
    end

    should 'display errors when a tag cannot be saved' do
      visit edit_tag_path(@tag)

      fill_in 'Title', with: ''
      click_on 'Save this section'

      assert page.has_content? "Title can't be blank"
    end

    should 'display a notice when the tag is saved' do
      visit edit_tag_path(@tag)

      click_on 'Save this section'

      assert page.has_content? 'Tag has been updated'
    end

    should 'show the curated list for a tag' do
      child_tag = create(:tag, title: 'MOT',
                               tag_id: 'driving/mot',
                               tag_type: 'section',
                               parent_id: 'driving')
      artefacts = create_list(:live_artefact, 5, kind: 'answer',
                                                 section_ids: [child_tag.tag_id])
      curated_list = create(:curated_list, slug: child_tag.tag_id.gsub('/','-'),
                                           tag_ids: [child_tag.tag_id],
                                           artefact_ids: artefacts.map(&:id))

      visit edit_tag_path(child_tag)

      within ".curated-artefact-group" do
        assert page.has_selector?('.curated-artefact', count: 5)

        artefacts.each_with_index do |artefact, i|
          selector = ".curated-artefact:nth-of-type(#{i+1})"

          within(selector) do
            assert page.has_select?('curated_list[artefact_ids][]', selected: artefact.name)
            assert page.has_button?('Remove curated item')
          end
        end
      end

      assert page.has_button?('Add another artefact')
    end
  end # given an existing live tag

  context 'editing a draft tag' do
    setup do
      @tag = create(:draft_tag, tag_type: 'section',
                                tag_id: 'driving',
                                title: 'Driving',
                                description: 'Car tax, MOTs and driving licences')
    end

    should 'display the form' do
      visit edit_tag_path(@tag)

      within 'header.artefact-header' do
        assert page.has_content?('Section: Driving')

        assert page.has_no_link?('/browse/driving')
        assert page.has_content?('/browse/driving')

        assert page.has_selector?('.state-draft', text: 'draft')
      end

      within 'form.tag' do
        assert page.has_field?('Title', with: @tag.title)
        assert page.has_field?('Description', with: @tag.description)
        assert page.has_button?('Save this section')
      end

      assert page.has_button?('Publish this section')
    end

    should 'not display a "Take care!" notice' do
      visit edit_tag_path(@tag)

      assert page.has_no_selector?('.take-care')
    end

    should 'display a notice when the tag is published' do
      visit edit_tag_path(@tag)

      click_on 'Publish this section'

      assert page.has_content? 'Tag has been published'
    end
  end

  context 'format JSON' do
    setup do
      @tag = create(:tag, tag_type: 'section', tag_id: 'tea', title: 'Tea')
    end

    should 'update an existing tag given valid parameters' do
      put tag_path(@tag), { title: 'Coffee', format: 'json' }

      assert_equal 200, response.status

      @tag.reload
      assert_equal 'Coffee', @tag.title
    end

    should 'return validation errors given invalid parameters' do
      put tag_path(@tag), { title: '', format: 'json' }
      body = JSON.parse(response.body)

      assert_equal 422, response.status
      assert_match /can't be blank/, body['errors']['title'].first

      @tag.reload
      assert_equal 'Tea', @tag.title
    end

    should 'return error when a change is requested to the tag_id' do
      put tag_path(@tag), { tag_id: 'foo', format: 'json' }
      body = JSON.parse(response.body)

      assert_equal 422, response.status
      assert_match "can't be changed", body['errors']['tag_id'].first
    end

    should 'return error when a change is requested to the parent_id' do
      put tag_path(@tag), { parent_id: 'foo', format: 'json' }
      body = JSON.parse(response.body)

      assert_equal 422, response.status
      assert_match "can't be changed", body['errors']['parent_id'].first
    end

    should 'return an error when the tag does not exist' do
      put tag_path('section/foo/bar'), { title: 'test', format: 'json' }

      assert_equal 404, response.status
    end
  end

end
