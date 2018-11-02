# frozen_string_literal: true
require 'spec_helper'

module Spree::GraphQL
  describe 'Types::Image' do
    let!(:image) { create(:image) }
    let!(:ctx) { { current_store: current_store } }
    let!(:variables) { }

    # altText: A word or phrase to share the nature or contents of an image.
    # @return [Types::String]
    describe 'altText' do
      let!(:query) { '{ image { altText } }' }
      let!(:result) { { data: { image: { altText: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # id: A unique identifier for the image.
    # @return [Types::ID]
    describe 'id' do
      let!(:query) { '{ image { id } }' }
      let!(:result) { { data: { image: { id: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # originalSrc: The location of the original (untransformed) image as a URL.
    # @return [Types::URL!]
    describe 'originalSrc' do
      let!(:query) { '{ image { originalSrc } }' }
      let!(:result) { { data: { image: { originalSrc: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

    # transformedSrc: The location of the transformed image as a URL. All transformation arguments are considered "best-effort". If they can be applied to an image, they will be. Otherwise any transformations which an image type does not support will be ignored. 
    # @param max_width [Types::Int]
    # @param max_height [Types::Int]
    # @param crop [Types::CropRegion]
    # @param scale [Types::Int] (1)
    # @param preferred_content_type [Types::ImageContentType]
    # @return [Types::URL!]
    describe 'transformedSrc' do
      let!(:query) { '{ image { transformedSrc } }' }
      let!(:result) { { data: { image: { transformedSrc: '' }}} }
      #it 'succeeds' do
      #  execute
      #  expect(response_hash).to eq(result_hash)
      #end
    end

  end
end
